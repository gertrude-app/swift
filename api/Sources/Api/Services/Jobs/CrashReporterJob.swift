import Dependencies
import Queues
import Vapor
import XCore

struct CrashReporterJob: AsyncScheduledJob {
  @Dependency(\.env) var env
  @Dependency(\.slack) var slack
  @Dependency(\.logger) var logger
  @Dependency(\.postmark) var postmark

  func run(context: QueueContext) async throws {
    if self.env.mode == .prod {
      await self.exec()
    }
  }

  func exec() async {
    let proc = Process()
    let pipe = Pipe()
    proc.standardOutput = pipe
    proc.executableURL = URL(fileURLWithPath: "/usr/bin/pm2")
    proc.arguments = ["jlist"]

    do {
      try proc.run()
    } catch {
      await self.slack.error("Error running crash report job: \(error)")
      return
    }

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let json = String(data: data, encoding: .utf8) else {
      await self.slack.error("Error parsing disk space check output")
      return
    }

    let processes: [Pm2Process]
    do {
      processes = try JSON.decode(json, as: [Pm2Process].self)
    } catch {
      await self.slack.error("Error decoding `pm2 jlist`: \(error)")
      return
    }

    guard let prod = processes.filter({ $0.name == "production" }).first else {
      await self.slack.error("Could not find production process in pm2 list")
      return
    }

    let num_crashes = prod.pm2_env.restart_time
    if num_crashes == 0 {
      self.logger.info("No crashes in production API detected")
      return
    }

    await self.slack.error("\(num_crashes) crashes detected in production API")
    self.postmark.toSuperAdmin("API Crashed", "\(num_crashes) times")
  }
}

private struct Pm2Process: Decodable {
  let name: String
  let pm2_env: Env

  struct Env: Decodable {
    let restart_time: Int
  }
}

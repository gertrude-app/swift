import Dependencies
import Queues
import Vapor

struct DiskSpaceJob: AsyncScheduledJob {
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
    proc.executableURL = URL(fileURLWithPath: "/usr/bin/bash")
    proc.arguments = [
      "-c",
      "df --output=pcent / | head -2 | tail -1 | awk '{print int($1)}' |  tr -d '\n'",
    ]

    do {
      try proc.run()
    } catch {
      await self.slack.sysLog("Error running disk space check: \(error)")
      return
    }

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let percent = Int(String(data: data, encoding: .utf8) ?? "") else {
      await self.slack.sysLog("Error parsing disk space check output")
      return
    }

    switch percent {
    case ..<45:
      await self.slack.sysLog("Unexpected disk usage amount: \(percent)%")
    case 45 ..< 89:
      self.logger.notice("Disk space looks OK: \(percent)%")
    default:
      await self.slack.sysLog("Disk space is dangerously low: \(percent)%")
      self.postmark.toSuperAdmin(
        "API Disk space dangerously low",
        "Disk space dangerously low: <code style='color: red;'>\(percent)%</code> used"
      )
    }
  }
}

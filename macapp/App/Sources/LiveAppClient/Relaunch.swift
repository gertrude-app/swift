import Darwin
import Foundation

@Sendable func relaunchApp() async throws {
  let relauncher = try relauncherUrl()
  try await precheck(relauncher)

  let proc = Process()
  proc.executableURL = relauncher
  proc.arguments = [Bundle.main.bundleURL.absoluteString, "--relaunch"]
  do {
    try proc.run()
  } catch {
    throw RelaunchError.relaunchProcessError("--relaunch", error)
  }

  try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
  exit(0)
}

@Sendable func startRelauncher() async throws -> pid_t {
  let relauncher = try relauncherUrl()
  try await precheck(relauncher)

  let proc = Process()
  proc.executableURL = relauncher
  proc.arguments = [Bundle.main.bundleURL.absoluteString, "--crash-watch"]
  do {
    try proc.run()
  } catch {
    throw RelaunchError.relaunchProcessError("--crash-watch", error)
  }

  return proc.processIdentifier
}

// safeguards before we terminate the app, verifies:
// 1) we can spawn and communicate w/ the relauncher
// 2) that the relauncher can find our app url bundle
@Sendable private func precheck(_ relauncher: URL) async throws {
  let proc = Process()
  let pipe = Pipe()
  proc.executableURL = relauncher
  proc.arguments = [Bundle.main.bundleURL.absoluteString, "--precheck"]
  proc.standardOutput = pipe

  do {
    try proc.run()
  } catch {
    throw RelaunchError.testProcessError(error)
  }

  proc.waitUntilExit()

  if proc.terminationStatus != 0 {
    throw RelaunchError.testFailedInvalidExit(proc.terminationStatus)
  }

  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  if let output = String(data: data, encoding: .utf8) {
    if output.trimmingCharacters(in: .whitespacesAndNewlines) != "OK" {
      throw RelaunchError.testFailedUnexpectedOutput(output)
    }
  }
}

private func relauncherUrl() throws -> URL {
  guard let relauncher = Bundle.main.sharedSupportURL?.appendingPathComponent("GertrudeHelper")
  else {
    throw RelaunchError.nilHelperUrl
  }

  guard FileManager.default.fileExists(atPath: relauncher.path) else {
    throw RelaunchError.helperNotFound
  }

  return relauncher
}

private enum RelaunchError: Error {
  case nilHelperUrl
  case helperNotFound
  case testFailedInvalidExit(Int32)
  case testFailedUnexpectedOutput(String)
  case testProcessError(Error)
  case relaunchProcessError(String, Error)
}

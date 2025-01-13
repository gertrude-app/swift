import Foundation
import Gertie
import os.log
import XCore

@Sendable func _preventScreenCaptureNag() async -> Result<Void, StringError> {
  let osVersion = Semver.fromOperatingSystemVersion()
  guard osVersion.major >= 15 else {
    os_log("[D•] skip screencapture nag fix, os: %{public}s", osVersion.string)
    return .success(())
  }

  let path = approvalFilepath()

  switch loadPlist(at: path) {
  case .success(var plist):
    updateApprovals(in: &plist, for: osVersion)
    switch write(plist, to: path) {
    case .success:
      return await restartReplayd()
    case .failure(let error):
      return .failure(error)
    }

  case .failure(let loadError):
    switch tryCreateApprovalFile(at: path, for: osVersion) {
    case .success:
      switch await restartReplayd() {
      case .success:
        return .success(())
      case .failure(let restartError):
        return .failure(loadError.merge(with: restartError))
      }
    case .failure(let createError):
      return .failure(loadError.merge(with: createError))
    }
  }
}

private func updateApprovals(in plist: inout [String: Any], for os: Semver) {
  // NB: fileformat changed between 15.0 and 15.1, see:
  // https://github.com/gertrude-app/project/issues/334#issuecomment-2568295348
  if os < .init("15.1.0")! {
    plist["/Applications/Gertrude.app/Contents/MacOS/Gertrude"] = Date() + .days(90)
  } else {
    let value: [String: Any] = [
      "kScreenCaptureAlertableUsageCount": Int(1),
      "kScreenCaptureApprovalLastAlerted": Date() + .days(90),
      "kScreenCaptureApprovalLastUsed": Date() + .days(90),
      "kScreenCapturePrivacyHintDate": Date() + .days(90),
      "kScreenCapturePrivacyHintPolicy": Int(TimeInterval.days(90)),
    ]
    plist["com.netrivet.gertrude.app"] = value
  }
}

func tryCreateApprovalFile(at url: URL, for os: Semver) -> Result<Void, StringError> {
  do {
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true,
      attributes: nil
    )
  } catch {
    return .failure(
      .init(
        oslogging: "error creating dir for plist file: \(error)",
        context: "DeviceClient.preventScreenCaptureNag+(_createApprovalFile)"
      )
    )
  }
  var plist: [String: Any] = [:]
  updateApprovals(in: &plist, for: os)
  return write(plist, to: url)
}

@Sendable func _testFullDiskAccess() async -> Bool {
  let fd = FileManager.default
  let path = "/Users/\(NSUserName())/Library/Mail/gertrude-FDA-\(UUID()).txt"
  let url = URL(fileURLWithPath: path)
  if !fd.fileExists(atPath: url.path) {
    let result = fd.createFile(atPath: url.path, contents: nil, attributes: nil)
    os_log("[D•] FDA test create result: %{public}s", "\(result)")
  }
  do {
    try "FDA test".write(toFile: url.path, atomically: true, encoding: .utf8)
    os_log("[G•] FDA test success")
    try? fd.removeItem(at: url)
    return true
  } catch {
    os_log("[G•] FDA test write error: %{public}s", String(reflecting: error))
    return false
  }
}

// helpers

private func write(_ plist: [String: Any], to url: URL) -> Result<Void, StringError> {
  do {
    let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
    try data.write(to: url)
    return .success(())
  } catch {
    return .failure(.init(
      oslogging: "error writing plist to path \(url.path): \(error)",
      context: "DeviceClient.preventScreenCaptureNag"
    ))
  }
}

private func loadPlist(at url: URL) -> Result<[String: Any], StringError> {
  do {
    let data = try Data(contentsOf: url)
    do {
      guard let plist = try PropertyListSerialization
        .propertyList(from: data, options: [], format: nil) as? [String: Any] else {
        return .failure(.init(
          oslogging: "got nil casting Data to [String: Any]",
          context: "DeviceClient.preventScreenCaptureNag"
        ))
      }
      return .success(plist)
    } catch {
      return .failure(.init(
        oslogging: "error casting Data to [String: Any]: \(error)",
        context: "DeviceClient.preventScreenCaptureNag"
      ))
    }
  } catch {
    return .failure(.init(
      oslogging: "error reading Data from plist file: \(error)",
      context: "DeviceClient.preventScreenCaptureNag"
    ))
  }
}

private func approvalFilepath() -> URL {
  let path = "/Users/\(NSUserName())/Library/Group Cont" +
    "ainers/gro" + "up.com.apple.repl" +
    "ayd/Screen" + "CaptureApp" + "rovals.plist"
  return URL(fileURLWithPath: path)
}

// killing the replayd daemon causes the system to restart it
// which forces a re-reading of the .plist file which we changed.
// without this, its possible (likely) that the daemon updates
// its in-memory data then overwrites our changes from the plist
private func restartReplayd() async -> Result<Void, StringError> {
  let task: Task<Result<Void, StringError>, Never> = Task {
    do {
      let proc = Process()
      let pipe = Pipe()
      proc.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
      proc.arguments = ["-9", "replayd"]
      proc.standardOutput = pipe
      try proc.run()
      proc.waitUntilExit()
      let exitCode = proc.terminationStatus
      if exitCode == 0 {
        return .success(())
      }
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      if let string = String(data: data, encoding: .utf8) {
        return .failure(.init(
          oslogging: "restart replayd failed w/ status \(exitCode) and output: \(string)",
          context: "DeviceClient.preventScreenCaptureNag(restartReplayd)"
        ))
      } else {
        return .failure(.init(
          oslogging: "restart replayd failed w/ status \(exitCode)",
          context: "DeviceClient.preventScreenCaptureNag(restartReplayd)"
        ))
      }
    } catch {
      return .failure(.init(
        oslogging: "restart replayd error: \(String(reflecting: error))",
        context: "DeviceClient.preventScreenCaptureNag(restartReplayd)"
      ))
    }
  }
  let result = await task.value
  if result.isSuccess {
    // give system time for restart and configuration read
    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
  }
  return result
}

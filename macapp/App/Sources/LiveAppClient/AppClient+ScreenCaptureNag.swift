import Core
import Foundation
import Gertie
import os.log

@Sendable func _preventScreenCaptureNag() async -> Result<Void, AppError> {
  let version = ProcessInfo.processInfo.operatingSystemVersion
  let macosVersion = Semver(
    major: version.majorVersion,
    minor: version.minorVersion,
    patch: version.patchVersion
  )
  guard macosVersion.major >= 15 else {
    os_log("[D•] skip screencapture nag fix, os: %{public}s", macosVersion.string)
    return .success(())
  }

  let path = approvalFilepath()
  switch loadPlist(at: path) {
  case .failure(let error):
    return .failure(error)
  case .success(var plist):
    // NB: fileformat changed between 15.0 and 15.1, see:
    // https://github.com/gertrude-app/project/issues/334#issuecomment-2568295348
    if macosVersion < .init("15.1.0")! {
      plist["/Applications/Gertrude.app/Contents/MacOS/Gertrude"] = Date() + .days(90)
    } else {
      let value: [String: Any] = [
        "kScreenCaptureAlertableUsageCount": Int(1),
        "kScreenCaptureApprovalLastAlerted": Date() + .days(90),
        "kScreenCaptureApprovalLastUsed": Date() + .days(90),
        "kScreenCapturePrivacyHintDate": Date() + .days(90),
      ]
      plist["com.netrivet.gertrude.app"] = value
    }
    return write(plist, to: path)
  }
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
    return true
  } catch {
    os_log("[G•] FDA test write error: %{public}s", String(reflecting: error))
    return false
  }
}

// helpers

private func write(_ plist: [String: Any], to url: URL) -> Result<Void, AppError> {
  do {
    let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
    try data.write(to: url)
    return .success(())
  } catch {
    return .failure(.init(
      oslogging: "error writing plist to file: \(error)",
      context: "DeviceClient.preventScreenCaptureNag"
    ))
  }
}

private func loadPlist(at url: URL) -> Result<[String: Any], AppError> {
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
  let home = FileManager.default.homeDirectoryForCurrentUser.path
  let path = "\(home)/Library/Group Cont" +
    "ainers/gro" + "up.com.apple.repl" +
    "ayd/Screen" + "CaptureApp" + "rovals.plist"
  return URL(fileURLWithPath: path)
}

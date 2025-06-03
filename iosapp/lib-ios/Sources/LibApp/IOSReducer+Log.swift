import os.log

extension IOSReducer.Deps {
  func log(_ msg: String, _ id: String) {
    #if !DEBUG
      Task { await self.api.logEvent(id, "[onboarding]: \(msg)") }
    #else
      if ProcessInfo.processInfo.environment["SWIFT_DETERMINISTIC_HASHING"] == nil {
        Task {
          await os_log("[G•] %{public}s", "[onboarding]: `\(id)` \(msg), \(self.eventMeta())\n")
          await print("\n[onboarding]: `\(id)` \(msg), \(self.eventMeta())\n")
        }
      }
    #endif
  }

  func log(
    _ screen: IOSReducer.Screen,
    _ action: IOSReducer.Action.Interactive,
    _ id: String,
    extra: String? = nil
  ) {
    self.log(screen, action: .interactive(action), id, extra: extra)
  }

  func log(
    _ action: IOSReducer.Action.Programmatic,
    _ id: String,
    extra: String? = nil
  ) {
    var msg = "received .\(shorten("\(action)"))"
    if let extra {
      msg += ", \(extra)"
    }
    self.log(msg, id)
  }

  func log(
    _ screen: IOSReducer.Screen,
    action: IOSReducer.Action,
    _ id: String,
    extra: String? = nil
  ) {
    var msg = "received .\(shorten("\(action)")) from screen .\(shorten("\(screen)"))"
    if let extra {
      msg += ", \(extra)"
    }
    self.log(msg, id)
  }

  func unexpected(
    _ screen: IOSReducer.Screen,
    _ action: IOSReducer.Action.Programmatic,
    _ id: String
  ) {
    self.log(
      "UNEXPECTED: received .\(shorten("\(IOSReducer.Action.programmatic(action))")) from screen .\(shorten("\(screen)"))",
      id
    )
  }

  private func eventMeta() async -> String {
    let device = await self.device.data()
    return "device: \(device.type), iOS: \(device.iOSVersion), vendorId: \(device.vendorId?.uuidString.lowercased() ?? "nil")"
  }
}

private func shorten(_ input: String) -> String {
  input
    .replacingOccurrences(of: "LibApp.IOSReducer.", with: "")
    .replacingOccurrences(of: "Action.Programmatic.", with: ".")
    .replacingOccurrences(of: "Action.Interactive.OnboardingBtn.", with: ".")
    .replacingOccurrences(of: "LibClients.DeviceClient.ClearCacheUpdate.", with: ".")
    .replacingOccurrences(of: "Action.Interactive.", with: ".")
    .replacingOccurrences(of: "Onboarding.HappyPath.", with: ".")
    .replacingOccurrences(of: "Onboarding.", with: ".")
    .replacingOccurrences(of: ".Major", with: "")
    .replacingOccurrences(of: ".Supervision", with: "")
    .replacingOccurrences(of: ".AuthFail", with: "")
    .replacingOccurrences(of: ".InstallFail", with: "")
    .replacingOccurrences(of: ".AppleFamily", with: "")
    .replacingOccurrences(of: ".InvalidAccount", with: "")
}

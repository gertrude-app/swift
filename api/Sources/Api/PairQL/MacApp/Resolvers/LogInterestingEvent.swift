import DuetSQL
import MacAppRoute

extension LogInterestingEvent: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let task = Task {
      // prevent FK error if device id deleted, or invalid
      let userDevice: UserDevice?
      if let deviceIdInput = input.deviceId,
         let device = try? await UserDevice.find(.init(deviceIdInput)) {
        userDevice = device
      } else {
        userDevice = nil
      }

      try await InterestingEvent.create(.init(
        eventId: input.eventId,
        kind: input.kind,
        context: "macapp",
        userDeviceId: userDevice?.id,
        adminId: nil,
        detail: input.detail
      ))

      let detail = input.detail.map { ", detail: _\(shorten($0))_" } ?? ""
      let searchLink = input.eventId.count == 8
        ? githubSearch(input.eventId)
        : "`\(input.eventId)`"
        .replacingOccurrences(of: "exec--App_", with: "")
        .replacingOccurrences(of: "--App/", with: "——")

      var adminLink = ""
      if let userDevice,
         let user = try? await userDevice.user(),
         let admin = try? await user.admin() {
        adminLink = "\n  -> " + Slack.link(
          to: "\(Env.ANALYTICS_SITE_URL)/admins/\(admin.id.lowercased)",
          withText: "\(admin.email), \(user.name)"
        )
      }

      if input.kind == "unexpected error" {
        await Current.slack.sysLog("Unexpected *macapp* error: \(searchLink)\(detail)\(adminLink)")
      } else {
        await Current.slack.sysLog("Macapp interesting event: \(searchLink)\(detail)\(adminLink)")
      }
    }

    if Env.mode == .test {
      try await task.value
    }

    return .success
  }
}

// helpers

private func shorten(_ detail: String) -> String {
  if detail.contains("Code=-1200") {
    return "SSL Error =-1200\(errorLoc(detail))"
  } else if detail.contains("Code=-1004") {
    return "Failed to Connect Error =-1004\(errorLoc(detail))"
  } else if detail.contains("Code=-1017") {
    return "Parse Response Error =-1017\(errorLoc(detail))"
  } else if detail.count > 100 {
    return detail.prefix(50) + " [...]"
  } else {
    return detail
  }
}

private func errorLoc(_ detail: String) -> String {
  if detail.contains("=https://gertrude.nyc3") {
    return " (spaces)"
  } else if detail.contains("=https://api.gertrude.app") {
    return " (API)"
  } else {
    return ""
  }
}

private func githubSearch(_ eventId: String) -> String {
  Slack.link(
    to: "https://github.com/search?q=repo%3Agertrude-app%2Fswift%20\(eventId)&type=code",
    withText: eventId
  )
}

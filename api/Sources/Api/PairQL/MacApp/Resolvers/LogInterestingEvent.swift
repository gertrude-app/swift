import DuetSQL
import MacAppRoute

extension LogInterestingEvent: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let task = Task {
      // prevent FK error if device id deleted, or invalid
      let userDevice: UserDevice?
      if let deviceIdInput = input.deviceId,
         let device = try? await context.db.find(UserDevice.Id(deviceIdInput)) {
        userDevice = device
      } else {
        userDevice = nil
      }

      try await context.db.create(InterestingEvent(
        eventId: input.eventId,
        kind: input.kind,
        context: "macapp",
        computerUserId: userDevice?.id,
        parentId: nil,
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
         let user = try? await userDevice.user(in: context.db),
         let admin = try? await user.admin(in: context.db) {
        adminLink = "\n  -> " + Slack.link(
          to: "\(context.env.analyticsSiteUrl)/admins/\(admin.id.lowercased)",
          withText: "\(admin.email), \(user.name)"
        )
      }

      if input.kind == "unexpected error" {
        await with(dependency: \.slack)
          .sysLog("Unexpected *macapp* error: \(searchLink)\(detail)\(adminLink)")
      } else {
        await with(dependency: \.slack)
          .sysLog("Macapp interesting event: \(searchLink)\(detail)\(adminLink)")
      }
    }

    if context.env.mode == .test {
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
  } else if detail.contains("[onboarding]") {
    return detail
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

func githubSearch(_ eventId: String) -> String {
  Slack.link(
    to: "https://github.com/search?q=repo%3Agertrude-app%2Fswift%20\(eventId)&type=code",
    withText: eventId
  )
}

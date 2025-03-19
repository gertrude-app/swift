import DuetSQL
import MacAppRoute

extension LogInterestingEvent: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let task = Task {
      // prevent FK error if device id deleted, or invalid
      let userDevice: UserDevice? = if let deviceId = input.deviceId {
        try? await context.db.find(UserDevice.Id(deviceId))
      } else {
        nil
      }

      try await context.db.create(InterestingEvent(
        eventId: input.eventId,
        kind: input.kind,
        context: "macapp",
        computerUserId: userDevice?.id,
        parentId: nil,
        detail: input.detail
      ))

      let adminLink = await getAdminLink(from: userDevice, in: context)
      let detail = input.detail.map { ", detail: _\(shorten($0))_" } ?? ""
      let searchLink = input.eventId.count == 8
        ? githubSearch(input.eventId)
        : "`\(input.eventId)`"
        .replacingOccurrences(of: "exec--App_", with: "")
        .replacingOccurrences(of: "--App/", with: "——")

      let slack = get(dependency: \.slack)
      if input.detail?.contains("[onboarding]") == true {
        await slack.internal(.macosOnboarding, "\(searchLink)\(detail)\(adminLink)")
      } else if input.detail?.contains("unexpected error") == true {
        await slack.internal(.unexpectedErrors, "macapp: \(searchLink)\(detail)\(adminLink)")
      } else if isUninterestingError(input.detail) {
        await slack.internal(.expectedErrors, "macapp: \(searchLink)\(detail)\(adminLink)")
      } else {
        await slack.internal(.macosLogs, "macapp: \(searchLink)\(detail)\(adminLink)")
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
    "SSL Error =-1200\(errorLoc(detail))"
  } else if detail.contains("Code=-1004") {
    "Failed to Connect Error =-1004\(errorLoc(detail))"
  } else if detail.contains("Code=-1017") {
    "Parse Response Error =-1017\(errorLoc(detail))"
  } else if detail.contains("[onboarding]") {
    detail
  } else if detail.count > 150 {
    detail.prefix(100) + " [...]"
  } else {
    detail
  }
}

private func errorLoc(_ detail: String) -> String {
  if detail.contains("=https://gertrude.nyc3") {
    " (spaces)"
  } else if detail.contains("=https://api.gertrude.app") {
    " (API)"
  } else {
    ""
  }
}

private func isUninterestingError(_ detail: String?) -> Bool {
  guard let detail else { return false }
  if detail.contains("Code=-1200") {
    return true
  } else if detail.contains("Code=-1004") {
    return true
  } else if detail.contains("Code=-1017") {
    return true
  } else if detail.contains("6e88d0de") { // user token missing
    return true
  } else {
    return false
  }
}

func githubSearch(_ eventId: String) -> String {
  Slack.link(
    to: "https://github.com/search?q=repo%3Agertrude-app%2Fswift%20\(eventId)&type=code",
    withText: eventId
  )
}

func getAdminLink(from userDevice: UserDevice?, in context: Context) async -> String {
  guard let userDevice,
        let user = try? await userDevice.user(in: context.db),
        let admin = try? await user.admin(in: context.db) else {
    return ""
  }
  return "\n  -> " + Slack.link(
    to: "\(context.env.analyticsSiteUrl)/admins/\(admin.id.lowercased)",
    withText: "\(admin.email), \(user.name)"
  )
}

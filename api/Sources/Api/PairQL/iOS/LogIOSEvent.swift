import IOSRoute

extension LogIOSEvent: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let detail = "\(input.detail ?? ""), " + [
      "device: `\(input.deviceType)`",
      "iOS: `\(input.iOSVersion)`",
      "vendorId: `\(input.vendorId?.lowercased ?? "(nil)")`",
    ].joined(separator: ", ")

    try await context.db.create(InterestingEvent(
      eventId: input.eventId,
      kind: input.kind,
      context: "ios",
      detail: detail
    ))

    if context.env.mode == .prod {
      let slack = get(dependency: \.slack)
      let message = "iOS app event: \(githubSearch(input.eventId)) \(detail)"
      if detail.contains("[onboarding]") {
        await slack.internal(.iosOnboarding, message)
      } else {
        await slack.internal(.iosLogs, message)
      }
    }

    return .success
  }
}

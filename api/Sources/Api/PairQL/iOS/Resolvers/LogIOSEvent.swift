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
      detail: detail,
    ))

    if context.env.mode == .prod {
      let slack = get(dependency: \.slack)
      let message = "iOS app event: \(githubSearch(input.eventId)) \(detail)"
      if detail.contains("[onboarding]")
        || input.eventId == "8d35f043" // first launch
        || input.eventId == "4a0c585f" // auth success
        || input.eventId == "adced334" { // filter install success
        await slack.internal(.iosOnboarding, message)
        // filter controller start/stop events, not very interesting
      } else if input.eventId == "00ec3909" || input.eventId == "8e23bea2" {
        await slack.internal(.debug, message)
      } else {
        await slack.internal(.iosLogs, message)
      }
    }

    return .success
  }
}

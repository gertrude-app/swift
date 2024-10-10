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
      await with(dependency: \.slack)
        .sysLog("iOS app event: \(githubSearch(input.eventId)) \(detail)")
    }

    return .success
  }
}

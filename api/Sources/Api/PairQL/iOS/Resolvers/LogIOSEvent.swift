import IOSRoute

extension LogIOSEvent: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let kind: IOSEvent.Kind = if input.detail?.contains("[onboarding]") == true {
      .onboarding
    } else if input.detail?.contains("controller proxy") == true
      || input.detail?.contains("filter install") == true {
      .filter
    } else {
      .info
    }

    var detail = input.detail
    if detail?.hasPrefix("[onboarding]: ") == true {
      detail = String(detail!.dropFirst("[onboarding]: ".count))
    }

    try await context.db.create(IOSEvent(
      eventId: input.eventId,
      kind: kind,
      detail: detail,
      vendorId: input.vendorId,
      deviceType: input.deviceType,
      iosVersion: input.iOSVersion,
    ))

    if context.env.mode != .prod {
      return .success
    }
    let slack = get(dependency: \.slack)
    let slackDetail = [
      input.detail,
      "device: `\(input.deviceType)`",
      "iOS: `\(input.iOSVersion)`",
      "vendorId: `\(input.vendorId?.lowercased ?? "(nil)")`",
    ].compactMap(\.self).joined(separator: ", ")
    let message = "iOS app event: \(githubSearch(input.eventId)) \(slackDetail)"
    if kind == .onboarding
      || input.eventId == "8d35f043" // first launch
      || input.eventId == "4a0c585f" // auth success
      || input.eventId == "adced334" { // filter install success
      await slack.internal(.iosOnboarding, message)
    } else if input.eventId == "00ec3909" || input.eventId == "8e23bea2" {
      await slack.internal(.debug, message)
    } else {
      await slack.internal(.iosLogs, message)
    }

    return .success
  }
}

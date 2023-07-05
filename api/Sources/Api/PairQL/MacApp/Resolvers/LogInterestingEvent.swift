import DuetSQL
import MacAppRoute

extension LogInterestingEvent: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    // prevent FK error if device id deleted, or invalid
    let deviceId: Device.Id?
    if let deviceIdInput = input.deviceId,
       let device = try? await Current.db.find(Device.Id(deviceIdInput)) {
      deviceId = device.id
    } else {
      deviceId = nil
    }

    if input.kind == "unexpected error" {
      await Current.slack.sysLog("Unexpected macapp error: `\(input.eventId)`")
    } else {
      await Current.slack.sysLog("Macapp interesting event: `\(input.eventId)`")
    }

    try await Current.db.create(InterestingEvent(
      eventId: input.eventId,
      kind: input.kind,
      context: "macapp",
      deviceId: deviceId,
      adminId: nil,
      detail: input.detail
    ))

    return .success
  }
}

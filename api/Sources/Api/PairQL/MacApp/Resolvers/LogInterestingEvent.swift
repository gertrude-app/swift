import DuetSQL
import MacAppRoute

extension LogInterestingEvent: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    // prevent FK error if device id deleted, or invalid
    let userDeviceId: UserDevice.Id?
    if let deviceIdInput = input.deviceId,
       let device = try? await Current.db.find(UserDevice.Id(deviceIdInput)) {
      userDeviceId = device.id
    } else {
      userDeviceId = nil
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
      userDeviceId: userDeviceId,
      adminId: nil,
      detail: input.detail
    ))

    return .success
  }
}

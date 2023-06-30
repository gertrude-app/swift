import DuetSQL
import MacAppRoute

extension LogUnexpectedError: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    // prevent FK error if device id deleted, or invalid
    let deviceId: Device.Id?
    if let deviceIdInput = input.deviceId,
       let device = try? await Current.db.find(Device.Id(deviceIdInput)) {
      deviceId = device.id
    } else {
      deviceId = nil
    }

    await Current.slack.sysLog("Unexpected macapp error: `\(input.errorId)`")

    try await Current.db.create(UnexpectedError(
      errorId: input.errorId,
      context: "macapp",
      deviceId: deviceId,
      adminId: nil,
      detail: input.detail
    ))

    return .success
  }
}

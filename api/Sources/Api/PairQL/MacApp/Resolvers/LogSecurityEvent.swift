import DuetSQL
import Gertie
import MacAppRoute

extension LogSecurityEvent: Resolver {
  static func resolve(with input: Input, in context: UserContext) async throws -> Output {
    guard let userDevice = try? await UserDevice.find(.init(input.deviceId)) else {
      await Current.slack
        .sysLog("UserDevice \(input.deviceId) not found, security event: \(input.event)")
      return .success
    }
    if let event = Gertie.SecurityEvent.MacApp(rawValue: input.event) {
      await Current.slack.sysLog("Recieved security event: `\(event)`") // temporary
    } else {
      await Current.slack.sysLog("Recieved unknown security event: `\(input.event)`")
    }
    let adminDevice = try await userDevice.adminDevice()
    try await Api.SecurityEvent(
      adminId: adminDevice.adminId,
      userDeviceId: userDevice.id,
      event: input.event,
      detail: input.detail
    ).create()
    // TODO: emit notification event
    return .success
  }
}

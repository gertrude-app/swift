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

    try await Api.SecurityEvent(
      adminId: context.user.adminId,
      userDeviceId: userDevice.id,
      event: input.event,
      detail: input.detail
    ).create()

    guard let event = Gertie.SecurityEvent.MacApp(rawValue: input.event) else {
      await Current.slack.sysLog(
        to: "errors",
        "Received unknown security event: `\(input.event)`"
      )
      return .success
    }

    // temp, while observing beta feature
    await Current.slack
      .sysLog("Received security event: `\(event)` for child: `\(context.user.name)`")

    if userDevice.isAdmin != true {
      return .success
    }

    await Current.adminNotifier.notify(
      context.user.adminId,
      .adminChildSecurityEvent(.init(
        userName: context.user.name,
        event: event,
        detail: input.detail
      ))
    )

    return .success
  }
}

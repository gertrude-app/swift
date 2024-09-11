import DuetSQL
import Gertie
import MacAppRoute

extension LogSecurityEvent: Resolver {
  static func resolve(with input: Input, in context: UserContext) async throws -> Output {
    guard let userDevice = try? await context.db.find(UserDevice.Id(input.deviceId)) else {
      await with(dependency: \.slack)
        .sysLog("UserDevice \(input.deviceId) not found, security event: \(input.event)")
      return .success
    }

    try await context.db.create(Api.SecurityEvent(
      adminId: context.user.adminId,
      userDeviceId: userDevice.id,
      event: input.event,
      detail: input.detail
    ))

    guard let event = Gertie.SecurityEvent.MacApp(rawValue: input.event) else {
      if input.event != "appUpdateInitiated" { // <-- removed for noise
        await with(dependency: \.slack)
          .sysLog(to: "errors", "Received unknown security event: `\(input.event)`")
      }
      return .success
    }

    if userDevice.isAdmin != true {
      return .success
    }

    await with(dependency: \.adminNotifier).notify(
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

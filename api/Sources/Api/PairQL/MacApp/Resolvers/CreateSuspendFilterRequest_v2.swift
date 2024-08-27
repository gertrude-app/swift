import MacAppRoute
import Vapor

extension CreateSuspendFilterRequest_v2: Resolver {
  static func resolve(with input: Input, in context: UserContext) async throws -> Output {
    let userDevice = try await context.userDevice()
    let request = try await Current.db.create(SuspendFilterRequest(
      userDeviceId: userDevice.id,
      status: .pending,
      scope: .unrestricted,
      duration: .init(input.duration),
      requestComment: input.comment
    ))

    await Current.adminNotifier.notify(
      context.user.adminId,
      .suspendFilterRequestSubmitted(.init(
        dashboardUrl: context.dashboardUrl,
        userDeviceId: userDevice.id,
        userId: context.user.id,
        userName: context.user.name,
        duration: .init(input.duration),
        requestId: request.id,
        requestComment: input.comment
      ))
    )

    return request.id.rawValue
  }
}

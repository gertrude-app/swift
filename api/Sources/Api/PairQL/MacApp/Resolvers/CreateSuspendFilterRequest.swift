import MacAppRoute
import Vapor

extension CreateSuspendFilterRequest: Resolver {
  static func resolve(with input: Input, in context: UserContext) async throws -> Output {
    let device = try await context.device()
    let request = try await Current.db.create(SuspendFilterRequest(
      deviceId: device.id,
      status: .pending,
      scope: .unrestricted,
      duration: .init(input.duration),
      requestComment: input.comment
    ))

    try await Current.adminNotifier.notify(
      context.user.adminId,
      .suspendFilterRequestSubmitted(.init(
        dashboardUrl: context.dashboardUrl,
        deviceId: device.id,
        userName: context.user.name,
        duration: .init(input.duration),
        requestId: request.id,
        requestComment: input.comment
      ))
    )

    return .success
  }
}

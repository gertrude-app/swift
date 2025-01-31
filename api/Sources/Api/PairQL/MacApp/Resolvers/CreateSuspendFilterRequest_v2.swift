import MacAppRoute
import Vapor

extension CreateSuspendFilterRequest_v2: Resolver {
  static func resolve(with input: Input, in context: UserContext) async throws -> Output {
    let userDevice = try await context.userDevice()
    let request = try await context.db.create(SuspendFilterRequest(
      computerUserId: userDevice.id,
      status: .pending,
      scope: .unrestricted,
      duration: .init(input.duration),
      requestComment: input.comment
    ))

    await with(dependency: \.adminNotifier).notify(
      context.user.parentId,
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

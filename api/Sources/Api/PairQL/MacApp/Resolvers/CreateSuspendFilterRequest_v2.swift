import MacAppRoute
import Vapor

extension CreateSuspendFilterRequest_v2: Resolver {
  static func resolve(with input: Input, in context: MacApp.ChildContext) async throws -> Output {
    let userDevice = try await context.userDevice()
    let request = try await context.db.create(MacApp.SuspendFilterRequest(
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
        childId: context.user.id,
        childName: context.user.name,
        duration: .init(input.duration),
        requestComment: input.comment,
        context: .macapp(computerUserId: userDevice.id, requestId: request.id)
      ))
    )

    return request.id.rawValue
  }
}

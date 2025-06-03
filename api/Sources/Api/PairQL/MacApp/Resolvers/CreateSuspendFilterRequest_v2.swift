import MacAppRoute
import Vapor

extension CreateSuspendFilterRequest_v2: Resolver {
  static func resolve(with input: Input, in context: MacApp.ChildContext) async throws -> Output {
    let computerUser = try await context.computerUser()
    let request = try await context.db.create(MacApp.SuspendFilterRequest(
      computerUserId: computerUser.id,
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
        context: .macapp(computerUserId: computerUser.id, requestId: request.id)
      ))
    )

    return request.id.rawValue
  }
}

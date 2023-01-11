import MacAppRoute

extension CreateUnlockRequests: Resolver {
  static func resolve(with inputs: Input, in context: UserContext) async throws -> Output {
    let device = try await context.device()
    let requests = inputs.map {
      UnlockRequest(
        networkDecisionId: .init(rawValue: $0.networkDecisionId),
        deviceId: device.id,
        requestComment: $0.comment,
        status: .pending
      )
    }

    try await Current.db.create(requests)

    try await Current.adminNotifier.notify(
      context.user.adminId,
      .unlockRequestSubmitted(.init(
        dashboardUrl: context.dashboardUrl,
        userId: context.user.id,
        userName: context.user.name,
        requestIds: requests.map(\.id)
      ))
    )

    return .success
  }
}

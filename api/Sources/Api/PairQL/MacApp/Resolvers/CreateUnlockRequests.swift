import MacAppRoute

extension CreateUnlockRequests: Resolver {
  static func resolve(with inputs: Input, in context: UserContext) async throws -> Output {
    let userDevice = try await context.userDevice()
    let requests = inputs.map {
      UnlockRequest(
        networkDecisionId: .init(rawValue: $0.networkDecisionId),
        userDeviceId: userDevice.id,
        requestComment: $0.comment,
        status: .pending
      )
    }

    try await Current.db.create(requests)

    await Current.adminNotifier.notify(
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

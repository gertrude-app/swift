import MacAppRoute

extension CreateUnlockRequests_v2: Resolver {
  static func resolve(with input: Input, in context: UserContext) async throws -> Output {
    let userDevice = try await context.userDevice()
    let networkDecisions = input.blockedRequests.map {
      NetworkDecision(
        userDeviceId: userDevice.id,
        verdict: .block,
        reason: .defaultNotAllowed,
        count: 1,
        hostname: $0.hostname,
        ipAddress: $0.ipAddress,
        url: $0.url,
        appBundleId: $0.bundleId,
        createdAt: $0.time
      )
    }
    try await Current.db.create(networkDecisions)

    let requests = networkDecisions.map {
      UnlockRequest(
        networkDecisionId: $0.id,
        userDeviceId: userDevice.id,
        requestComment: input.comment,
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

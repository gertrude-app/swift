import MacAppRoute

extension CreateUnlockRequests_v3: Resolver {
  static func resolve(with input: Input, in context: UserContext) async throws -> Output {
    let userDevice = try await context.userDevice()

    let requests = try await context.db.create(input.blockedRequests.map {
      UnlockRequest(
        computerUserId: userDevice.id,
        appBundleId: $0.bundleId,
        url: $0.url,
        hostname: $0.hostname,
        ipAddress: $0.ipAddress,
        requestComment: input.comment,
        status: .pending
      )
    })

    await with(dependency: \.adminNotifier).notify(
      context.user.parentId,
      .unlockRequestSubmitted(.init(
        dashboardUrl: context.dashboardUrl,
        userId: context.user.id,
        userName: context.user.name,
        requestIds: requests.map(\.id)
      ))
    )

    return requests.map(\.id.rawValue)
  }
}

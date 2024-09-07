import MacAppRoute

extension CreateUnlockRequests_v3: Resolver {
  static func resolve(with input: Input, in context: UserContext) async throws -> Output {
    let userDevice = try await context.userDevice()

    let requests = try await context.db.create(input.blockedRequests.map {
      UnlockRequest(
        userDeviceId: userDevice.id,
        appBundleId: $0.bundleId,
        url: $0.url,
        hostname: $0.hostname,
        ipAddress: $0.ipAddress,
        requestComment: input.comment,
        status: .pending
      )
    })

    await Current.adminNotifier.notify(
      context.user.adminId,
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

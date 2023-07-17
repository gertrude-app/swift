import MacAppRoute

extension CreateNetworkDecisions: Resolver {
  static func resolve(
    with inputs: [DecisionInput],
    in context: UserContext
  ) async throws -> Output {
    let userDevice = try await context.userDevice()
    let decisions = inputs.map { input in
      NetworkDecision(
        id: input.id.map { .init($0) } ?? .init(),
        userDeviceId: userDevice.id,
        responsibleKeyId: input.responsibleKeyId.map { .init($0) },
        verdict: input.verdict,
        reason: input.reason,
        count: input.count,
        ipProtocolNumber: input.ipProtocolNumber,
        hostname: input.hostname,
        ipAddress: input.ipAddress,
        url: input.url,
        appBundleId: input.appBundleId,
        createdAt: input.time
      )
    }
    try await Current.db.create(decisions)
    return .success
  }
}

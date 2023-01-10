import MacAppRoute

extension CreateNetworkDecisions: Resolver {
  static func resolve(
    with inputs: [DecisionInput],
    in context: UserContext
  ) async throws -> Output {
    let device = try await context.device()
    let decisions = inputs.map { input in
      NetworkDecision(
        id: input.id.map { .init($0) } ?? .init(),
        deviceId: device.id,
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

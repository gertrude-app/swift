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

    // TODO: event, notify connected app
    // let payload = Event.Payload.UnlockRequestSubmitted(
    //   adminId: user.adminId,
    //   userId: user.id,
    //   userName: user.name,
    //   requests: requests.map(\.id)
    // )
    // try await Current.events.receive(.unlockRequestSubmitted(payload))

    return .success
  }
}

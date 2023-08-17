import Gertie
import PairQL

struct UpdateUnlockRequest: Pair {
  static var auth: ClientAuth = .admin

  struct Input: PairInput {
    let id: UnlockRequest.Id
    let responseComment: String?
    let status: RequestStatus
  }
}

// resolver

extension UpdateUnlockRequest: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    let request = try await Current.db.find(input.id)
    let userDevice = try await request.userDevice()
    try await context.verifiedUser(from: userDevice.userId)
    request.responseComment = input.responseComment
    request.status = input.status
    try await Current.db.update(request)
    let decision = try await Current.db.find(request.networkDecisionId)

    try await Current.connectedApps.notify(.unlockRequestUpdated(.init(
      userDeviceId: userDevice.id,
      status: request.status,
      target: decision.target ?? "",
      comment: request.requestComment,
      responseComment: request.responseComment
    )))

    return .success
  }
}

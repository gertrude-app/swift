import Shared
import TypescriptPairQL

struct UpdateUnlockRequest: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Input: TypescriptPairInput {
    let id: UnlockRequest.Id
    let responseComment: String?
    let status: RequestStatus
  }
}

// resolver

extension UpdateUnlockRequest: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    let request = try await Current.db.find(input.id)
    let device = try await request.device()
    try await context.verifiedUser(from: device.userId)
    request.responseComment = input.responseComment
    request.status = input.status
    try await Current.db.update(request)
    let decision = try await Current.db.find(request.networkDecisionId)

    await Current.connectedApps.notify(.unlockRequestUpdated(.init(
      deviceId: device.id,
      status: request.status,
      target: decision.target ?? "",
      comment: request.requestComment,
      responseComment: request.responseComment
    )))

    return .success
  }
}

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
    try await context.verifiedUser(from: try await request.device().userId)
    request.responseComment = input.responseComment
    request.status = input.status
    try await Current.db.update(request)
    // @TODO: notify via websocket
    return .success
  }
}

import Gertie
import PairQL

struct UpdateUnlockRequest: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let id: UnlockRequest.Id
    let responseComment: String?
    let status: RequestStatus
  }
}

// resolver

extension UpdateUnlockRequest: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    var unlockRequest = try await context.db.find(input.id)
    let userDevice = try await unlockRequest.computerUser(in: context.db)
    try await context.verifiedChild(from: userDevice.childId)
    unlockRequest.responseComment = input.responseComment
    unlockRequest.status = input.status
    try await context.db.update(unlockRequest)
    try await with(dependency: \.websockets).send(
      .unlockRequestUpdated_v2(
        id: unlockRequest.id.rawValue,
        status: unlockRequest.status,
        target: unlockRequest.target ?? "",
        comment: unlockRequest.responseComment
      ),
      to: .userDevice(userDevice.id)
    )
    return .success
  }
}

import Gertie
import PairQL

struct UpdateUnlockRequest: Pair {
  static let auth: ClientAuth = .admin

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
    let userDevice = try await unlockRequest.userDevice(in: context.db)
    try await context.verifiedUser(from: userDevice.userId)
    unlockRequest.responseComment = input.responseComment
    unlockRequest.status = input.status
    try await context.db.update(unlockRequest)
    try await Current.websockets.send(
      unlockRequest.updated(for: userDevice.appSemver),
      to: .userDevice(userDevice.id)
    )
    return .success
  }
}

// extensions

extension UnlockRequest {
  func updated(for version: Semver) -> WebSocketMessage.FromApiToApp {
    if version >= .init("2.4.0")! {
      return .unlockRequestUpdated_v2(
        id: self.id.rawValue,
        status: self.status,
        target: self.target ?? "",
        comment: self.responseComment
      )
    } else {
      return .unlockRequestUpdated(
        status: self.status,
        target: self.target ?? "",
        parentComment: self.responseComment
      )
    }
  }
}

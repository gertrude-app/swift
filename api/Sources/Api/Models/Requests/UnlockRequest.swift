import DuetSQL
import Gertie

final class UnlockRequest: Codable {
  var id: Id
  var networkDecisionId: NetworkDecision.Id
  var userDeviceId: UserDevice.Id
  var status: RequestStatus
  var requestComment: String?
  var responseComment: String?
  var createdAt = Date()
  var updatedAt = Date()

  var networkDecision = Parent<NetworkDecision>.notLoaded
  var userDevice = Parent<UserDevice>.notLoaded

  init(
    id: Id = .init(),
    networkDecisionId: NetworkDecision.Id,
    userDeviceId: UserDevice.Id,
    requestComment: String? = nil,
    responseComment: String? = nil,
    status: RequestStatus = .pending
  ) {
    self.id = id
    self.networkDecisionId = networkDecisionId
    self.userDeviceId = userDeviceId
    self.status = status
    self.requestComment = requestComment
    self.responseComment = responseComment
  }
}

// loaders

extension UnlockRequest {
  func networkDecision() async throws -> NetworkDecision {
    try await networkDecision.useLoaded(or: {
      try await Current.db.query(NetworkDecision.self)
        .where(.id == networkDecisionId)
        .first()
    })
  }

  func userDevice() async throws -> UserDevice {
    try await userDevice.useLoaded(or: {
      try await Current.db.query(UserDevice.self)
        .where(.id == userDeviceId)
        .first()
    })
  }
}

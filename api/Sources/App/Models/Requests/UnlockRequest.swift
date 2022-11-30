import Duet
import Shared

final class UnlockRequest: Codable {
  var id: Id
  var networkDecisionId: NetworkDecision.Id
  var deviceId: Device.Id
  var status: RequestStatus
  var requestComment: String?
  var responseComment: String?
  var createdAt = Date()
  var updatedAt = Date()

  var networkDecision = Parent<NetworkDecision>.notLoaded
  var device = Parent<Device>.notLoaded

  init(
    id: Id = .init(),
    networkDecisionId: NetworkDecision.Id,
    deviceId: Device.Id,
    requestComment: String? = nil,
    responseComment: String? = nil,
    status: RequestStatus = .pending
  ) {
    self.id = id
    self.networkDecisionId = networkDecisionId
    self.deviceId = deviceId
    self.status = status
    self.requestComment = requestComment
    self.responseComment = responseComment
  }
}

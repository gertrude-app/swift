import DuetSQL
import Gertie
import TaggedTime

struct SuspendFilterRequest: Codable, Sendable {
  var id: Id
  var userDeviceId: UserDevice.Id
  var status: RequestStatus
  var scope: AppScope
  var duration: Seconds<Int>
  var requestComment: String?
  var responseComment: String?
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id = .init(),
    userDeviceId: UserDevice.Id,
    status: RequestStatus = .pending,
    scope: AppScope,
    duration: Seconds<Int> = 180,
    requestComment: String? = nil,
    responseComment: String? = nil
  ) {
    self.id = id
    self.userDeviceId = userDeviceId
    self.status = status
    self.scope = scope
    self.duration = duration
    self.requestComment = requestComment
    self.responseComment = responseComment
  }
}

// loaders

extension SuspendFilterRequest {
  func userDevice() async throws -> UserDevice {
    try await Current.db.query(UserDevice.self)
      .where(.id == self.userDeviceId)
      .first()
  }
}

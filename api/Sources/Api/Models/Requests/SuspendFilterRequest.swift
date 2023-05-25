import DuetSQL
import Gertie
import TaggedTime

final class SuspendFilterRequest: Codable {
  var id: Id
  var deviceId: Device.Id
  var status: RequestStatus
  var scope: AppScope
  var duration: Seconds<Int>
  var requestComment: String?
  var responseComment: String?
  var createdAt = Date()
  var updatedAt = Date()

  var device = Parent<Device>.notLoaded

  init(
    id: Id = .init(),
    deviceId: Device.Id,
    status: RequestStatus = .pending,
    scope: AppScope,
    duration: Seconds<Int> = 180,
    requestComment: String? = nil,
    responseComment: String? = nil
  ) {
    self.id = id
    self.deviceId = deviceId
    self.status = status
    self.scope = scope
    self.duration = duration
    self.requestComment = requestComment
    self.responseComment = responseComment
  }
}

// loaders

extension SuspendFilterRequest {
  func device() async throws -> Device {
    try await device.useLoaded(or: {
      try await Current.db.query(Device.self)
        .where(.id == deviceId)
        .first()
    })
  }
}

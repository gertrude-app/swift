import DuetSQL
import Gertie

final class UnlockRequest: Codable {
  var id: Id
  var userDeviceId: UserDevice.Id
  var status: RequestStatus
  var appBundleId: String
  var requestComment: String?
  var responseComment: String?
  var url: String?
  var hostname: String?
  var ipAddress: String?
  var createdAt = Date()
  var updatedAt = Date()

  var userDevice = Parent<UserDevice>.notLoaded

  var target: String? {
    url ?? hostname ?? ipAddress
  }

  init(
    id: Id = .init(),
    userDeviceId: UserDevice.Id,
    appBundleId: String,
    url: String? = nil,
    hostname: String? = nil,
    ipAddress: String? = nil,
    requestComment: String? = nil,
    responseComment: String? = nil,
    status: RequestStatus = .pending
  ) {
    self.id = id
    self.userDeviceId = userDeviceId
    self.status = status
    self.appBundleId = appBundleId
    self.url = url
    self.hostname = hostname
    self.ipAddress = ipAddress
    self.requestComment = requestComment
    self.responseComment = responseComment
  }
}

// loaders

extension UnlockRequest {
  func userDevice() async throws -> UserDevice {
    try await userDevice.useLoaded(or: {
      try await Current.db.query(UserDevice.self)
        .where(.id == userDeviceId)
        .first()
    })
  }
}

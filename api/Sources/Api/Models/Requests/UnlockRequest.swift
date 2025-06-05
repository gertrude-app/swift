import DuetSQL
import Gertie

struct UnlockRequest: Codable, Sendable {
  var id: Id
  var computerUserId: ComputerUser.Id
  var status: RequestStatus
  var appBundleId: String
  var requestComment: String?
  var responseComment: String?
  var url: String?
  var hostname: String?
  var ipAddress: String?
  var createdAt = Date()
  var updatedAt = Date()

  var target: String? {
    self.url ?? self.hostname ?? self.ipAddress
  }

  init(
    id: Id = .init(),
    computerUserId: ComputerUser.Id,
    appBundleId: String,
    url: String? = nil,
    hostname: String? = nil,
    ipAddress: String? = nil,
    requestComment: String? = nil,
    responseComment: String? = nil,
    status: RequestStatus = .pending
  ) {
    self.id = id
    self.computerUserId = computerUserId
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
  func computerUser(in db: any DuetSQL.Client) async throws -> ComputerUser {
    try await ComputerUser.query()
      .where(.id == self.computerUserId)
      .first(in: db)
  }
}

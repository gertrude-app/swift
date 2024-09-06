import DuetSQL
import Gertie
import TaggedTime

struct SuspendFilterRequest: Codable, Sendable, Equatable {
  var id: Id
  var userDeviceId: UserDevice.Id
  var status: RequestStatus
  var scope: AppScope
  var duration: Seconds<Int>
  var requestComment: String?
  var responseComment: String?
  var extraMonitoring: String?
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id = .init(),
    userDeviceId: UserDevice.Id,
    status: RequestStatus = .pending,
    scope: AppScope,
    duration: Seconds<Int> = 180,
    requestComment: String? = nil,
    responseComment: String? = nil,
    extraMonitoring: String? = nil
  ) {
    self.id = id
    self.userDeviceId = userDeviceId
    self.status = status
    self.scope = scope
    self.duration = duration
    self.requestComment = requestComment
    self.responseComment = responseComment
    self.extraMonitoring = extraMonitoring
  }
}

// loaders

extension SuspendFilterRequest {
  func userDevice() async throws -> UserDevice {
    try await UserDevice.query()
      .where(.id == self.userDeviceId)
      .first()
  }

  var decision: FilterSuspensionDecision? {
    switch self.status {
    case .pending:
      return nil
    case .rejected:
      return .rejected
    case .accepted:
      return .accepted(
        duration: self.duration,
        extraMonitoring: self.extraMonitoring
          .flatMap(FilterSuspensionDecision.ExtraMonitoring.init(magicString:))
      )
    }
  }
}

import DuetSQL
import Gertie
import TaggedTime

extension MacApp {
  struct SuspendFilterRequest: Codable, Sendable, Equatable {
    var id: Id
    var computerUserId: ComputerUser.Id
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
      computerUserId: ComputerUser.Id,
      status: RequestStatus = .pending,
      scope: AppScope,
      duration: Seconds<Int> = 180,
      requestComment: String? = nil,
      responseComment: String? = nil,
      extraMonitoring: String? = nil
    ) {
      self.id = id
      self.computerUserId = computerUserId
      self.status = status
      self.scope = scope
      self.duration = duration
      self.requestComment = requestComment
      self.responseComment = responseComment
      self.extraMonitoring = extraMonitoring
    }
  }
}

// loaders

extension MacApp.SuspendFilterRequest {
  func computerUser(in db: any DuetSQL.Client) async throws -> ComputerUser {
    try await ComputerUser.query()
      .where(.id == self.computerUserId)
      .first(in: db)
  }

  var decision: FilterSuspensionDecision? {
    switch self.status {
    case .pending:
      nil
    case .rejected:
      .rejected
    case .accepted:
      .accepted(
        duration: self.duration,
        extraMonitoring: self.extraMonitoring
          .flatMap(FilterSuspensionDecision.ExtraMonitoring.init(magicString:))
      )
    }
  }
}

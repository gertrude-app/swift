import FluentSQL
import Shared

struct RequestTables: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.create(enum: RequestStatus.self)
    try await upNetworkDecisions(sql)
    try await upUnlockRequests(sql)
    try await upSuspendFilterRequests(sql)
  }

  func down(sql: SQLDatabase) async throws {
    try await downSuspendFilterRequests(sql)
    try await downUnlockRequests(sql)
    try await downNetworkDecisions(sql)
    try await sql.drop(enum: RequestStatus.self)
  }

  // table: network_decisions

  let networkDecisionDeviceFk = Constraint.foreignKey(
    from: NetworkDecision.M5.self,
    to: Device.M3.self,
    thru: NetworkDecision.M5.deviceId,
    onDelete: .cascade
  )

  let networkDecisionKeyFk = Constraint.foreignKey(
    from: NetworkDecision.M5.self,
    to: Key.M2.self,
    thru: NetworkDecision.M5.responsibleKeyId,
    onDelete: .cascade
  )

  func upNetworkDecisions(_ sql: SQLDatabase) async throws {
    typealias M = NetworkDecision.M5

    try await sql.create(enum: NetworkDecision.Verdict.self)
    try await sql.create(enum: NetworkDecision.Reason.self)

    try await sql.create(table: NetworkDecision.M5.self) {
      Column(.id, .uuid, .primaryKey)
      Column(M.deviceId, .uuid)
      Column(M.verdict, .enum(NetworkDecision.Verdict.self))
      Column(M.reason, .enum(NetworkDecision.Reason.self))
      Column(M.ipProtocolNumber, .bigint, .nullable)
      Column(M.hostname, .text, .nullable)
      Column(M.ipAddress, .text, .nullable)
      Column(M.url, .text, .nullable)
      Column(M.appBundleId, .text, .nullable)
      Column(M.count, .bigint)
      Column(M.responsibleKeyId, .uuid, .nullable)
      Column(.createdAt, .timestampWithTimezone)
    }

    try await sql.add(constraint: networkDecisionDeviceFk)
    try await sql.add(constraint: networkDecisionKeyFk)
  }

  func downNetworkDecisions(_ sql: SQLDatabase) async throws {
    try await sql.drop(constraint: networkDecisionDeviceFk)
    try await sql.drop(constraint: networkDecisionKeyFk)
    try await sql.drop(table: NetworkDecision.M5.self)
    try await sql.drop(enum: NetworkDecision.Verdict.self)
    try await sql.drop(enum: NetworkDecision.Reason.self)
  }

  // table: unlock_requests

  let unlockRequestDeviceFk = Constraint.foreignKey(
    from: UnlockRequest.M5.self,
    to: Device.M3.self,
    thru: UnlockRequest.M5.deviceId,
    onDelete: .cascade
  )

  let unlockRequestNetworkDecisionFk = Constraint.foreignKey(
    from: UnlockRequest.M5.self,
    to: NetworkDecision.M5.self,
    thru: UnlockRequest.M5.networkDecisionId,
    onDelete: .cascade
  )

  func upUnlockRequests(_ sql: SQLDatabase) async throws {
    try await sql.create(table: UnlockRequest.M5.self) {
      Column(.id, .uuid, .primaryKey)
      Column(UnlockRequest.M5.networkDecisionId, .uuid)
      Column(UnlockRequest.M5.deviceId, .uuid)
      Column(UnlockRequest.M5.status, .enum(RequestStatus.self))
      Column(UnlockRequest.M5.requestComment, .text, .nullable)
      Column(UnlockRequest.M5.responseComment, .text, .nullable)
      Column(.createdAt, .timestampWithTimezone)
      Column(.updatedAt, .timestampWithTimezone)
    }
    try await sql.add(constraint: unlockRequestDeviceFk)
    try await sql.add(constraint: unlockRequestNetworkDecisionFk)
  }

  func downUnlockRequests(_ sql: SQLDatabase) async throws {
    try await sql.drop(constraint: unlockRequestNetworkDecisionFk)
    try await sql.drop(constraint: unlockRequestDeviceFk)
    try await sql.drop(table: UnlockRequest.M5.self)
  }

  // table: suspend_filter_requests

  let suspendFilterRequestFk = Constraint.foreignKey(
    from: SuspendFilterRequest.M5.self,
    to: Device.M3.self,
    thru: SuspendFilterRequest.M5.deviceId,
    onDelete: .cascade
  )

  func upSuspendFilterRequests(_ sql: SQLDatabase) async throws {
    try await sql.create(table: SuspendFilterRequest.M5.self) {
      Column(.id, .uuid, .primaryKey)
      Column(SuspendFilterRequest.M5.deviceId, .uuid)
      Column(SuspendFilterRequest.M5.status, .enum(RequestStatus.self))
      Column(SuspendFilterRequest.M5.scope, .jsonb)
      Column(SuspendFilterRequest.M5.duration, .bigint)
      Column(SuspendFilterRequest.M5.requestComment, .text, .nullable)
      Column(SuspendFilterRequest.M5.responseComment, .text, .nullable)
      Column(.createdAt, .timestampWithTimezone)
      Column(.updatedAt, .timestampWithTimezone)
    }
    try await sql.add(constraint: suspendFilterRequestFk)
  }

  func downSuspendFilterRequests(_ sql: SQLDatabase) async throws {
    try await sql.drop(constraint: suspendFilterRequestFk)
    try await sql.drop(table: SuspendFilterRequest.M5.self)
  }
}

// migration extensions

extension RequestTables {
  enum M5 {
    static let requestStatusTypeName = "enum_shared_request_status"
  }
}

extension NetworkDecision {
  enum M5: TableNamingMigration {
    static let tableName = "network_decisions"
    static let verdictTypeName = "enum_network_decision_verdict"
    static let reasonTypeName = "enum_network_decision_reason"
    static let deviceId = FieldKey("device_id")
    static let verdict = FieldKey("verdict")
    static let reason = FieldKey("reason")
    static let ipProtocolNumber = FieldKey("ip_protocol_number")
    static let hostname = FieldKey("hostname")
    static let ipAddress = FieldKey("ip_address")
    static let url = FieldKey("url")
    static let appBundleId = FieldKey("app_bundle_id")
    static let count = FieldKey("count")
    static let responsibleKeyId = FieldKey("responsible_key_id")
  }
}

extension UnlockRequest {
  enum M5: TableNamingMigration {
    static let tableName = "unlock_requests"
    static let networkDecisionId = FieldKey("network_decision_id")
    static let deviceId = FieldKey("device_id")
    static let status = FieldKey("status")
    static let requestComment = FieldKey("request_comment")
    static let responseComment = FieldKey("response_comment")
  }
}

extension SuspendFilterRequest {
  enum M5: TableNamingMigration {
    static let tableName = "suspend_filter_requests"
    static let deviceId = FieldKey("device_id")
    static let status = FieldKey("status")
    static let scope = FieldKey("scope")
    static let duration = FieldKey("duration")
    static let requestComment = FieldKey("request_comment")
    static let responseComment = FieldKey("response_comment")
  }
}

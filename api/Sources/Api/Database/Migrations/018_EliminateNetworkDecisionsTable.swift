import Dependencies
import DuetSQL
import FluentSQL
import Gertie

struct EliminateNetworkDecisionsTable: GertieMigration {
  func up(sql: SQLDatabase) async throws {

    #if !DEBUG
      // query legacy data for migration
      @Dependency(\.db) var db
      let decisions = try await db.customQuery(LegacyDecisions.self)
      let unlockRequestIds = try await db.customQuery(UnlockRequestIds.self)
    #endif

    // alter unlock_requests table
    try await sql.drop(constraint: RequestTables().unlockRequestNetworkDecisionFk)
    try await sql.dropColumn(
      UnlockRequest.M5.networkDecisionId,
      on: UnlockRequest.M5.self
    )
    try await sql.addColumn(
      UnlockRequest.M18.appBundleId,
      on: UnlockRequest.M5.self,
      type: .text,
      default: .text("--temp--") // temp, during migration
    )
    try await sql.addColumn(
      UnlockRequest.M18.url,
      on: UnlockRequest.M5.self,
      type: .text,
      nullable: true
    )
    try await sql.addColumn(
      UnlockRequest.M18.hostname,
      on: UnlockRequest.M5.self,
      type: .text,
      nullable: true
    )
    try await sql.addColumn(
      UnlockRequest.M18.ipAddress,
      on: UnlockRequest.M5.self,
      type: .text,
      nullable: true
    )

    #if !DEBUG
      // transfer data from network_decisions to unlock_requests
      for unlock in unlockRequestIds {
        guard let decision = decisions.first(where: { $0.id == unlock.networkDecisionId }) else {
          fatalError("Decision not found for unlock request `\(unlock.id)`")
        }
        try await sql.execute("""
          UPDATE \(table: UnlockRequest.M5.self)
          SET
            \(col: UnlockRequest.M18.appBundleId) = '\(unsafeRaw: decision.appBundleId)',
            \(col: UnlockRequest.M18.url) = \(nullable: decision.url),
            \(col: UnlockRequest.M18.hostname) = \(nullable: decision.hostname),
            \(col: UnlockRequest.M18.ipAddress) = \(nullable: decision.ipAddress)
          WHERE \(col: .id) = '\(uuid: unlock.id)'
        """)
      }
    #endif

    // remove temporary default, all rows should have a real value now
    // and all new rows will have a value
    try await sql.dropDefault(from: UnlockRequest.M18.appBundleId, on: UnlockRequest.M5.self)

    // drop network_decisions table
    try await sql.drop(constraint: RequestTables().networkDecisionKeyFk)
    try await sql.drop(constraint: DeviceRefactor().networkDecisionFk)
    try await sql.drop(table: Deleted.NetworkDecisionTable.M5.self)
    try await sql.drop(enum: NetworkDecisionVerdict.self)
    try await sql.drop(enum: NetworkDecisionReason.self)
  }

  func down(sql: SQLDatabase) async throws {
    // recreate network_decisions table
    try await sql.create(enum: NetworkDecisionVerdict.self)
    try await sql.create(enum: NetworkDecisionReason.self)
    try await sql.create(table: Deleted.NetworkDecisionTable.M5.self) {
      Column(.id, .uuid, .primaryKey)
      Column(Deleted.NetworkDecisionTable.M11.userDeviceId, .uuid)
      Column(Deleted.NetworkDecisionTable.M5.verdict, .enum(NetworkDecisionVerdict.self))
      Column(Deleted.NetworkDecisionTable.M5.reason, .enum(NetworkDecisionReason.self))
      Column(Deleted.NetworkDecisionTable.M5.ipProtocolNumber, .bigint, .nullable)
      Column(Deleted.NetworkDecisionTable.M5.hostname, .text, .nullable)
      Column(Deleted.NetworkDecisionTable.M5.ipAddress, .text, .nullable)
      Column(Deleted.NetworkDecisionTable.M5.url, .text, .nullable)
      Column(Deleted.NetworkDecisionTable.M5.appBundleId, .text, .nullable)
      Column(Deleted.NetworkDecisionTable.M5.count, .bigint)
      Column(Deleted.NetworkDecisionTable.M5.responsibleKeyId, .uuid, .nullable)
      Column(.createdAt, .timestampWithTimezone)
    }
    try await sql.add(constraint: RequestTables().networkDecisionKeyFk)
    try await sql.add(constraint: DeviceRefactor().networkDecisionFk)

    // drop all unlock_requests, we don't have required FK to restore them
    // and they are transient requests anyway, and this down should never run in prod
    try await sql.execute("DELETE FROM \(table: UnlockRequest.M5.self)")

    // restore unlock_requests table
    try await sql.dropColumn(UnlockRequest.M18.appBundleId, on: UnlockRequest.M5.self)
    try await sql.dropColumn(UnlockRequest.M18.url, on: UnlockRequest.M5.self)
    try await sql.dropColumn(UnlockRequest.M18.hostname, on: UnlockRequest.M5.self)
    try await sql.dropColumn(UnlockRequest.M18.ipAddress, on: UnlockRequest.M5.self)
    try await sql.addColumn(
      UnlockRequest.M5.networkDecisionId,
      on: UnlockRequest.M5.self,
      type: .uuid
    )
    try await sql.add(constraint: RequestTables().unlockRequestNetworkDecisionFk)
  }
}

// extensions

extension UnlockRequest {
  enum M18 {
    static let appBundleId = FieldKey("app_bundle_id")
    static let url = FieldKey("url")
    static let hostname = FieldKey("hostname")
    static let ipAddress = FieldKey("ip_address")
  }
}

// query

private struct LegacyDecisions: CustomQueryable {
  var id: UUID
  var appBundleId: String
  var url: String?
  var hostname: String?
  var ipAddress: String?

  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    .init("""
    SELECT
      id,
      \(Deleted.NetworkDecisionTable.M5.appBundleId),
      \(Deleted.NetworkDecisionTable.M5.url),
      \(Deleted.NetworkDecisionTable.M5.hostname),
      \(Deleted.NetworkDecisionTable.M5.ipAddress)
    FROM \(Deleted.NetworkDecisionTable.M5.tableName)
    """)
  }
}

private struct UnlockRequestIds: CustomQueryable {
  var id: UUID
  var networkDecisionId: UUID

  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    .init("""
    SELECT id, \(UnlockRequest.M5.networkDecisionId)
    FROM \(UnlockRequest.M5.tableName)
    """)
  }
}

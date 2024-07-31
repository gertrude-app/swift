import DuetSQL
import FluentSQL
import Gertie

struct ModifySecurityEventsTable: GertieMigration {
  let securityEventAdminIdFk = Constraint.foreignKey(
    from: SecurityEvent.M21.self,
    to: Admin.M1.self,
    thru: SecurityEvent.M21.adminId,
    onDelete: .cascade
  )

  func up(sql: SQLDatabase) async throws {
    try await sql.add(constraint: self.securityEventAdminIdFk)
    try await sql.addColumn(
      SecurityEvent.M23.ipAddress,
      on: SecurityEvent.M21.self,
      type: .varchar(64),
      nullable: true
    )
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.dropColumn(SecurityEvent.M23.ipAddress, on: SecurityEvent.M21.self)
    try await sql.drop(constraint: self.securityEventAdminIdFk)
  }
}

extension SecurityEvent {
  enum M23 {
    static let ipAddress = FieldKey("ip_address")
  }
}

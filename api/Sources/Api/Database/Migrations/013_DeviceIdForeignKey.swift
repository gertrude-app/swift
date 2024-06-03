import FluentSQL

struct DeviceIdForeignKey: GertieMigration {
  let fk = Constraint.foreignKey(
    from: UserDevice.M11.self,
    to: Device.M3.self,
    thru: UserDevice.M11.deviceId,
    onDelete: .cascade
  )

  func up(sql: SQLDatabase) async throws {
    try await sql.add(constraint: self.fk)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.drop(constraint: self.fk)
  }
}

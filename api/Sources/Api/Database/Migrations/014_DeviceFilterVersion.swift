import FluentSQL

struct DeviceFilterVersion: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.addColumn(
      Device.M14.filterVersion,
      on: Device.M3.self,
      type: .varchar(12),
      nullable: true
    )
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.dropColumn(Device.M14.filterVersion, on: Device.M3.self)
  }
}

extension Device {
  enum M14 {
    static let filterVersion = FieldKey("filter_version")
  }
}

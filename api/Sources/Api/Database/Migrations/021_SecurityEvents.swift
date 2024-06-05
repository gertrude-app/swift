import FluentSQL
import Gertie

struct SecurityEvents: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.addColumn(
      UserDevice.M20.isAdmin,
      on: UserDevice.M11.self,
      type: .boolean,
      nullable: true
    )
    try await sql.addColumn(
      Device.M20.osVersion,
      on: Device.M3.self,
      type: .varchar(12),
      nullable: true
    )
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.dropColumn(UserDevice.M20.isAdmin, on: UserDevice.M11.self)
    try await sql.dropColumn(Device.M20.osVersion, on: Device.M3.self)
  }
}

extension UserDevice {
  enum M20 {
    static let isAdmin = FieldKey("is_admin")
  }
}

extension Device {
  enum M20 {
    static let osVersion = FieldKey("os_version")
  }
}

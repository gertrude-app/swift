import FluentSQL
import Gertie

struct AddAdminGclid: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.addColumn(
      Admin.M19.gclid,
      on: Admin.M1.self,
      type: .varchar(128),
      nullable: true
    )
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.dropColumn(Admin.M19.gclid, on: Admin.M1.self)
  }
}

extension Admin {
  enum M19 {
    static let gclid = FieldKey("gclid")
  }
}

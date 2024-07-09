import DuetSQL
import FluentSQL
import Gertie

struct ABTestVariants: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.addColumn(
      Admin.M22.abTestVariant,
      on: Admin.M1.self,
      type: .varchar(255),
      nullable: true
    )
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.dropColumn(Admin.M22.abTestVariant, on: Admin.M1.self)
  }
}

extension Admin {
  enum M22 {
    static let abTestVariant = FieldKey("ab_test_variant")
  }
}

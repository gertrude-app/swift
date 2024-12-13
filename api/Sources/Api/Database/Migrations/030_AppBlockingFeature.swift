import FluentSQL
import Foundation
import Gertie

struct AppBlockingFeature: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await self.modifyUnidentifiedAppsUp(sql: sql)

    try await sql.dropColumn(
      IdentifiedApp.M6.description,
      on: IdentifiedApp.M6.self
    )
    try await sql.renameColumn(
      on: IdentifiedApp.M6.self,
      from: IdentifiedApp.M6.selectable,
      to: IdentifiedApp.M30.launchable
    )

    try await sql.create(table: UserBlockedApp.M30.self) {
      Column(.id, .uuid, .primaryKey)
      Column(UserBlockedApp.M30.userId, .uuid)
      Column(UserBlockedApp.M30.identifier, .text)
      Column(UserBlockedApp.M30.schedule, .jsonb, .nullable)
      Column(.createdAt, .timestampWithTimezone)
      Column(.updatedAt, .timestampWithTimezone)
    }

    try await sql.add(constraint: .foreignKey(
      from: UserBlockedApp.M30.self,
      to: User.M3.self,
      thru: UserBlockedApp.M30.userId,
      onDelete: .cascade
    ))
  }

  func down(sql: SQLDatabase) async throws {
    try await self.modifyUnidentifiedAppsDown(sql: sql)

    try await sql.renameColumn(
      on: IdentifiedApp.M6.self,
      from: IdentifiedApp.M30.launchable,
      to: IdentifiedApp.M6.selectable
    )
    try await sql.addColumn(
      IdentifiedApp.M6.description,
      on: IdentifiedApp.M6.self,
      type: .text,
      nullable: true
    )
    try await sql.drop(table: UserBlockedApp.M30.self)
  }

  func modifyUnidentifiedAppsUp(sql: SQLDatabase) async throws {
    try await sql.addColumn(
      UnidentifiedApp.M30.bundleName,
      on: UnidentifiedApp.M28.self,
      type: .text,
      nullable: true
    )
    try await sql.addColumn(
      UnidentifiedApp.M30.localizedName,
      on: UnidentifiedApp.M28.self,
      type: .text,
      nullable: true
    )
    try await sql.addColumn(
      UnidentifiedApp.M30.launchable,
      on: UnidentifiedApp.M28.self,
      type: .boolean,
      nullable: true
    )
  }

  func modifyUnidentifiedAppsDown(sql: SQLDatabase) async throws {
    try await sql.dropColumn(
      UnidentifiedApp.M30.launchable,
      on: UnidentifiedApp.M28.self
    )
    try await sql.dropColumn(
      UnidentifiedApp.M30.localizedName,
      on: UnidentifiedApp.M28.self
    )
    try await sql.dropColumn(
      UnidentifiedApp.M30.bundleName,
      on: UnidentifiedApp.M28.self
    )
  }
}

extension IdentifiedApp {
  enum M30 {
    static let launchable = FieldKey("launchable")
  }
}

extension UnidentifiedApp {
  enum M30 {
    static let launchable = FieldKey("launchable")
    static let bundleName = FieldKey("bundle_name")
    static let localizedName = FieldKey("localized_name")
  }
}

extension UserBlockedApp {
  enum M30: TableNamingMigration {
    static let tableName = "blocked_apps"
    static let identifier = FieldKey("identifier")
    static let userId = FieldKey("user_id")
    static let schedule = FieldKey("schedule")
    static let createdAt = FieldKey("created_at")
    static let updatedAt = FieldKey("updated_at")
  }
}

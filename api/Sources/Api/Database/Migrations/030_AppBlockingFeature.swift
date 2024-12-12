import FluentSQL
import Foundation
import Gertie

struct AppBlockingFeature: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await self.modifyIdentifiedAppsUp(sql: sql)

    try await sql.create(table: BlockedApp.M30.self) {
      Column(.id, .uuid, .primaryKey)
      Column(BlockedApp.M30.appId, .uuid)
      Column(BlockedApp.M30.userId, .uuid)
      Column(BlockedApp.M30.schedule, .jsonb, .nullable)
      Column(.createdAt, .timestampWithTimezone)
      Column(.updatedAt, .timestampWithTimezone)
    }

    try await sql.add(constraint: .foreignKey(
      from: BlockedApp.M30.self,
      to: IdentifiedApp.M6.self,
      thru: BlockedApp.M30.appId,
      onDelete: .noAction
    ))

    try await sql.add(constraint: .foreignKey(
      from: BlockedApp.M30.self,
      to: User.M3.self,
      thru: BlockedApp.M30.userId,
      onDelete: .cascade
    ))

    try await sql.create(table: DeviceApp.M30.self) {
      Column(.id, .uuid, .primaryKey)
      Column(DeviceApp.M30.deviceId, .uuid)
      Column(DeviceApp.M30.appId, .uuid)
      Column(.createdAt, .timestampWithTimezone)
      Column(.updatedAt, .timestampWithTimezone)
    }

    try await sql.add(constraint: .foreignKey(
      from: DeviceApp.M30.self,
      to: Device.M3.self,
      thru: DeviceApp.M30.deviceId,
      onDelete: .cascade
    ))

    try await sql.add(constraint: .foreignKey(
      from: DeviceApp.M30.self,
      to: IdentifiedApp.M6.self,
      thru: DeviceApp.M30.appId,
      onDelete: .noAction
    ))
  }

  func down(sql: SQLDatabase) async throws {
    try await self.modifyIdentifiedAppsDown(sql: sql)
    try await sql.drop(table: BlockedApp.M30.self)
    try await sql.drop(table: DeviceApp.M30.self)
  }

  func modifyIdentifiedAppsUp(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE \(table: IdentifiedApp.M6.self)
      DROP CONSTRAINT identified_apps_name_key
    """)
    try await sql.execute("""
      ALTER TABLE \(table: IdentifiedApp.M6.self)
      ALTER COLUMN \(col: IdentifiedApp.M6.name) DROP NOT NULL
    """)
    try await sql.dropColumn(
      IdentifiedApp.M6.description,
      on: IdentifiedApp.M6.self
    )
    try await sql.renameColumn(
      on: IdentifiedApp.M6.self,
      from: IdentifiedApp.M6.selectable,
      to: IdentifiedApp.M30.launchable
    )
    try await sql.renameColumn(
      on: IdentifiedApp.M6.self,
      from: IdentifiedApp.M6.name,
      to: IdentifiedApp.M30.customName
    )
    try await sql.addColumn(
      IdentifiedApp.M30.bundleName,
      on: IdentifiedApp.M6.self,
      type: .text,
      nullable: true
    )
    try await sql.addColumn(
      IdentifiedApp.M30.localizedName,
      on: IdentifiedApp.M6.self,
      type: .text,
      nullable: true
    )
    try await sql.add(constraint: .unique(
      IdentifiedApp.M6.self,
      IdentifiedApp.M30.bundleName
    ))
    try await sql.execute("""
      ALTER TABLE \(table: IdentifiedApp.M6.self)
      ADD CONSTRAINT one_non_null_name
      CHECK (
        bundle_name IS NOT NULL OR
        localized_name IS NOT NULL OR
        custom_name IS NOT NULL
      );
    """)
  }

  func modifyIdentifiedAppsDown(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE \(table: IdentifiedApp.M6.self)
      DROP CONSTRAINT one_non_null_name;
    """)
    try await sql.renameColumn(
      on: IdentifiedApp.M6.self,
      from: IdentifiedApp.M30.launchable,
      to: IdentifiedApp.M6.selectable
    )
    try await sql.renameColumn(
      on: IdentifiedApp.M6.self,
      from: IdentifiedApp.M30.customName,
      to: IdentifiedApp.M6.name
    )
    try await sql.execute("""
      UPDATE \(table: IdentifiedApp.M6.self)
      SET \(col: IdentifiedApp.M6.name) =\(col: IdentifiedApp.M30.bundleName)
      WHERE \(col: IdentifiedApp.M6.name) IS NULL;
    """)
    try await sql.execute("""
      UPDATE \(table: IdentifiedApp.M6.self)
      SET \(col: IdentifiedApp.M6.name) =\(col: IdentifiedApp.M30.localizedName)
      WHERE \(col: IdentifiedApp.M6.name) IS NULL;
    """)
    try await sql.dropColumn(
      IdentifiedApp.M30.bundleName,
      on: IdentifiedApp.M6.self
    )
    try await sql.dropColumn(
      IdentifiedApp.M30.localizedName,
      on: IdentifiedApp.M6.self
    )
    try await sql.addColumn(
      IdentifiedApp.M6.description,
      on: IdentifiedApp.M6.self,
      type: .text,
      nullable: true
    )
    try await sql.execute("""
      ALTER TABLE \(table: IdentifiedApp.M6.self)
      ALTER COLUMN \(col: IdentifiedApp.M6.name) SET NOT NULL
    """)
    try await sql.execute("""
      ALTER TABLE \(table: IdentifiedApp.M6.self)
      ADD CONSTRAINT identified_apps_name_key UNIQUE (\(col: IdentifiedApp.M6.name))
    """)
  }
}

extension IdentifiedApp {
  enum M30 {
    static let launchable = FieldKey("launchable")
    static let customName = FieldKey("custom_name")
    static let bundleName = FieldKey("bundle_name")
    static let localizedName = FieldKey("localized_name")
  }
}

extension BlockedApp {
  enum M30: TableNamingMigration {
    static let tableName = "blocked_apps"
    static let appId = FieldKey("app_id")
    static let userId = FieldKey("user_id")
    static let schedule = FieldKey("schedule")
    static let createdAt = FieldKey("created_at")
    static let updatedAt = FieldKey("updated_at")
  }
}

extension DeviceApp {
  enum M30: TableNamingMigration {
    static let tableName = "device_apps"
    static let deviceId = FieldKey("device_id")
    static let appId = FieldKey("app_id")
    static let createdAt = FieldKey("created_at")
    static let updatedAt = FieldKey("updated_at")
  }
}

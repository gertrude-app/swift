import FluentSQL

struct AppTables: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await upAppCategories(sql)
    try await upIdentifiedApps(sql)
    try await upAppBundleIds(sql)
  }

  func down(sql: SQLDatabase) async throws {
    try await downAppBundleIds(sql)
    try await downIdentifiedApps(sql)
    try await downAppCategories(sql)
  }

  // table: app_categories

  func upAppCategories(_ sql: SQLDatabase) async throws {
    try await sql.create(table: AppCategory.M6.self) {
      Column(.id, .uuid, .primaryKey)
      Column(AppCategory.M6.name, .text, .unique)
      Column(AppCategory.M6.slug, .text, .unique)
      Column(AppCategory.M6.description, .text, .nullable)
      Column(.createdAt, .timestampWithTimezone)
      Column(.updatedAt, .timestampWithTimezone)
    }
  }

  func downAppCategories(_ sql: SQLDatabase) async throws {
    try await sql.drop(table: AppCategory.M6.self)
  }

  // table: identified_apps

  let identifiedAppsFk = Constraint.foreignKey(
    from: IdentifiedApp.M6.self,
    to: AppCategory.M6.self,
    thru: IdentifiedApp.M6.categoryId,
    onDelete: .cascade
  )

  func upIdentifiedApps(_ sql: SQLDatabase) async throws {
    try await sql.create(table: IdentifiedApp.M6.self) {
      Column(.id, .uuid, .primaryKey)
      Column(IdentifiedApp.M6.name, .text, .unique)
      Column(IdentifiedApp.M6.slug, .text, .unique)
      Column(IdentifiedApp.M6.selectable, .boolean)
      Column(IdentifiedApp.M6.categoryId, .uuid, .nullable)
      Column(IdentifiedApp.M6.description, .text, .nullable)
      Column(.createdAt, .timestampWithTimezone)
      Column(.updatedAt, .timestampWithTimezone)
    }
    try await sql.add(constraint: identifiedAppsFk)
  }

  func downIdentifiedApps(_ sql: SQLDatabase) async throws {
    try await sql.drop(constraint: identifiedAppsFk)
    try await sql.drop(table: IdentifiedApp.M6.self)
  }

  // table: app_bundle_ids

  let appBundleIdFk = Constraint.foreignKey(
    from: AppBundleId.M6.self,
    to: IdentifiedApp.M6.self,
    thru: AppBundleId.M6.identifiedAppId,
    onDelete: .cascade
  )

  func upAppBundleIds(_ sql: SQLDatabase) async throws {
    try await sql.create(table: AppBundleId.M6.self) {
      Column(.id, .uuid, .primaryKey)
      Column(AppBundleId.M6.bundleId, .text, .unique)
      Column(AppBundleId.M6.identifiedAppId, .uuid)
      Column(.createdAt, .timestampWithTimezone)
      Column(.updatedAt, .timestampWithTimezone)
    }
    try await sql.add(constraint: appBundleIdFk)
  }

  func downAppBundleIds(_ sql: SQLDatabase) async throws {
    try await sql.drop(constraint: appBundleIdFk)
    try await sql.drop(table: AppBundleId.M6.self)
  }
}

// migration extensions

extension IdentifiedApp {
  enum M6: TableNamingMigration {
    static let tableName = "identified_apps"
    static let name = FieldKey("name")
    static let slug = FieldKey("slug")
    static let selectable = FieldKey("selectable")
    static let categoryId = FieldKey("category_id")
    static let description = FieldKey("description")
  }
}

extension AppCategory {
  enum M6: TableNamingMigration {
    static let tableName = "app_categories"
    static let name = FieldKey("name")
    static let slug = FieldKey("slug")
    static let description = FieldKey("description")
  }
}

extension AppBundleId {
  enum M6: TableNamingMigration {
    static let tableName = "app_bundle_ids"
    static let bundleId = FieldKey("bundle_id")
    static let identifiedAppId = FieldKey("identified_app_id")
  }
}

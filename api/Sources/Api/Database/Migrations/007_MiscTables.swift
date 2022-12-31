import FluentSQL

struct MiscTables: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await upReleases(sql)
    try await upStripeEvents(sql)
  }

  func down(sql: SQLDatabase) async throws {
    try await downReleases(sql)
    try await downStripeEvents(sql)
  }

  // table: releases

  func upReleases(_ sql: SQLDatabase) async throws {
    try await sql.create(enum: Release.Channel.self)
    try await sql.create(table: Release.M7.self) {
      Column(.id, .uuid, .primaryKey)
      Column(Release.M7.semver, .text, .unique)
      Column(Release.M7.channel, .enum(Release.Channel.self))
      Column(Release.M7.signature, .text)
      Column(Release.M7.length, .bigint)
      Column(Release.M7.appRevision, .text)
      Column(Release.M7.coreRevision, .text)
      Column(.createdAt, .timestampWithTimezone)
      Column(.updatedAt, .timestampWithTimezone)
    }
  }

  func downReleases(_ sql: SQLDatabase) async throws {
    try await sql.drop(table: Release.M7.self)
    try await sql.drop(enum: Release.Channel.self)
  }

  // table: stripe_events

  func upStripeEvents(_ sql: SQLDatabase) async throws {
    try await sql.create(table: StripeEvent.M7.self) {
      Column(.id, .uuid, .primaryKey)
      Column(StripeEvent.M7.json, .text)
      Column(.createdAt, .timestampWithTimezone)
    }
  }

  func downStripeEvents(_ sql: SQLDatabase) async throws {
    try await sql.drop(table: StripeEvent.M7.self)
  }
}

// migration extensions

extension Release {
  enum M7: TableNamingMigration {
    static let tableName = "releases"
    static let channelTypeName = "enum_release_channels"
    static let semver = FieldKey("semver")
    static let channel = FieldKey("channel")
    static let signature = FieldKey("signature")
    static let length = FieldKey("length")
    static let appRevision = FieldKey("app_revision")
    static let coreRevision = FieldKey("core_revision")
  }
}

extension StripeEvent {
  enum M7: TableNamingMigration {
    static let tableName = "stripe_events"
    static let json = FieldKey("json")
  }
}

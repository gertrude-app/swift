import FluentSQL
import XCore

struct AdminVerifiedNotificationMethodCodableUpdate: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    let rows = try await sql
      .execute("SELECT id, config from \(table: AdminVerifiedNotificationMethod.M1.self)")

    for row in rows {
      let (id, config) = (
        try row.decode(column: "id", as: UUID.self),
        try row.decode(column: "config", as: LegacyAdminVerifiedNotificationMethodConfig.self)
      )
      try await sql.execute("""
        UPDATE \(table: AdminVerifiedNotificationMethod.M1.self)
        SET config = '\(raw: try JSON.encode(config.toCurrent))'
        WHERE id = '\(raw: id.uuidString)'
      """)
    }
  }

  func down(sql: SQLDatabase) async throws {
    let rows = try await sql
      .execute("SELECT id, config from \(table: AdminVerifiedNotificationMethod.M1.self)")

    for row in rows {
      let (id, config) = (
        try row.decode(column: "id", as: UUID.self),
        try row.decode(column: "config", as: AdminVerifiedNotificationMethod.Config.self)
      )
      try await sql.execute("""
        UPDATE \(table: AdminVerifiedNotificationMethod.M1.self)
        SET config = '\(raw: try JSON.encode(config.toLegacy))'
        WHERE id = '\(raw: id.uuidString)'
      """)
    }
  }
}

// legacy codable conversions

enum LegacyAdminVerifiedNotificationMethodConfig: Codable {
  // same structure as current, but letting Swift use the default Codable we used to use
  case slack(channelId: String, channelName: String, token: String)
  case email(email: String)
  case text(phoneNumber: String)

  var toCurrent: AdminVerifiedNotificationMethod.Config {
    switch self {
    case .slack(channelId: let channelId, channelName: let channelName, token: let token):
      return .slack(channelId: channelId, channelName: channelName, token: token)
    case .email(email: let email):
      return .email(email: email)
    case .text(phoneNumber: let phoneNumber):
      return .text(phoneNumber: phoneNumber)
    }
  }
}

private extension AdminVerifiedNotificationMethod.Config {
  var toLegacy: LegacyAdminVerifiedNotificationMethodConfig {
    switch self {
    case .slack(channelId: let channelId, channelName: let channelName, token: let token):
      return .slack(channelId: channelId, channelName: channelName, token: token)
    case .email(email: let email):
      return .email(email: email)
    case .text(phoneNumber: let phoneNumber):
      return .text(phoneNumber: phoneNumber)
    }
  }
}

import DuetSQL
import FluentSQL
import Foundation
import GertieIOS
import XCore

struct ReencodeIOSBlockRules: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    let rows = try await sql.execute(
      """
      SELECT id, rule::TEXT
      FROM iosapp.block_rules
      """
    )

    let records = try rows.map { row in
      let id: UUID = try row.decode(column: "id")
      let json: String = try row.decode(column: "rule")
      let legacyRule = try JSON.decode(json, as: BlockRule.Legacy.self)
      return (id: id, legacyRule: legacyRule)
    }

    for record in records {
      let json = try JSON.encode(record.legacyRule.current)
      try await sql.execute(
        """
        UPDATE iosapp.block_rules
        SET rule = '\(unsafeRaw: json)'::JSONB
        WHERE id = '\(uuid: record.id)'
        """
      )
    }
  }

  func down(sql: SQLDatabase) async throws {
    let rows = try await sql.execute(
      """
      SELECT id, rule::TEXT
      FROM iosapp.block_rules
      """
    )

    let records = try rows.map { row in
      let id: UUID = try row.decode(column: "id")
      let json: String = try row.decode(column: "rule")
      let rule = try JSON.decode(json, as: BlockRule.self)
      return (id: id, rule: rule)
    }

    for record in records {
      let json = try JSON.encode(record.rule.legacy)
      try await sql.execute(
        """
        UPDATE iosapp.block_rules
        SET rule = '\(unsafeRaw: json)'::JSONB
        WHERE id = '\(uuid: record.id)'
        """
      )
    }
  }
}

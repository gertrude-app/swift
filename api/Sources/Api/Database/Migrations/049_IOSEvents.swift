import FluentSQL
import Foundation

struct IOSEvents: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE iosapp.events (
        id uuid NOT NULL,
        vendor_id uuid,
        event_id text NOT NULL,
        kind text NOT NULL CHECK (kind IN ('info', 'onboarding', 'filter', 'error')),
        detail text,
        device_type varchar(32) NOT NULL CHECK (device_type IN ('iPhone', 'iPad')),
        ios_version varchar(32) NOT NULL,
        created_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY iosapp.events
      ADD CONSTRAINT iosapp_events_pkey PRIMARY KEY (id);
    """)

    let rows = try await sql.execute("""
      SELECT id, event_id, detail, created_at
      FROM system.interesting_events
      WHERE context = 'ios'
    """)

    var valuesClauses: [String] = []
    for row in rows {
      let id: UUID = try row.decode(column: "id")
      let eventId: String = try row.decode(column: "event_id")
      let rawDetail: String = try row.decode(column: "detail")
      let createdAt: Date = try row.decode(column: "created_at")

      let parsed = parseDetail(rawDetail)

      let kind = if rawDetail.contains("[onboarding]") {
        "onboarding"
      } else if rawDetail.contains("controller proxy") || rawDetail.contains("filter install") {
        "filter"
      } else {
        "info"
      }

      var detail = parsed.detail
      if detail?.hasPrefix("[onboarding]: ") == true {
        detail = String(detail!.dropFirst("[onboarding]: ".count))
      }
      let detailValue = detail.map { "'\(escape($0))'" } ?? "NULL"
      let vendorValue = parsed.vendorId.map { "'\($0.uuidString)'" } ?? "NULL"
      let timestamp = formatTimestamp(createdAt)

      valuesClauses.append("""
      ('\(id.uuidString)', '\(escape(eventId))', '\(kind)', \(detailValue), \
      \(vendorValue), '\(escape(parsed.deviceType))', '\(escape(parsed.iOSVersion))', \
      '\(timestamp)')
      """)

      if valuesClauses.count >= batchSize {
        try await insertBatch(sql: sql, table: "iosapp.events", values: valuesClauses)
        valuesClauses.removeAll()
      }
    }

    if !valuesClauses.isEmpty {
      try await insertBatch(sql: sql, table: "iosapp.events", values: valuesClauses)
    }

    try await sql.execute("""
      DELETE FROM system.interesting_events WHERE context = 'ios'
    """)
  }

  func down(sql: SQLDatabase) async throws {
    let rows = try await sql.execute("""
      SELECT id, event_id, kind, detail, vendor_id, device_type, ios_version, created_at
      FROM iosapp.events
    """)

    var valuesClauses: [String] = []
    for row in rows {
      let id: UUID = try row.decode(column: "id")
      let eventId: String = try row.decode(column: "event_id")
      let kind: String = try row.decode(column: "kind")
      var detail: String? = try row.decode(column: "detail")
      let vendorId: UUID? = try row.decode(column: "vendor_id")
      let deviceType: String = try row.decode(column: "device_type")
      let iOSVersion: String = try row.decode(column: "ios_version")
      let createdAt: Date = try row.decode(column: "created_at")

      if kind == "onboarding", let d = detail {
        detail = "[onboarding]: " + d
      }

      let reconstructed = reconstructDetail(
        detail: detail,
        deviceType: deviceType,
        iOSVersion: iOSVersion,
        vendorId: vendorId,
      )
      let timestamp = formatTimestamp(createdAt)

      valuesClauses.append("""
      ('\(id.uuidString)', '\(escape(eventId))', 'ios', 'ios', \
      '\(escape(reconstructed))', '\(timestamp)')
      """)

      if valuesClauses.count >= batchSize {
        try await insertBatch(
          sql: sql,
          table: "system.interesting_events",
          columns: "(id, event_id, kind, context, detail, created_at)",
          values: valuesClauses,
        )
        valuesClauses.removeAll()
      }
    }

    if !valuesClauses.isEmpty {
      try await insertBatch(
        sql: sql,
        table: "system.interesting_events",
        columns: "(id, event_id, kind, context, detail, created_at)",
        values: valuesClauses,
      )
    }

    try await sql.execute("DROP TABLE iosapp.events;")
  }
}

// helpers

private let batchSize = 5000

private struct ParsedDetail {
  var detail: String?
  var deviceType: String
  var iOSVersion: String
  var vendorId: UUID?
}

private func insertBatch(
  sql: SQLDatabase,
  table: String,
  columns: String = "(id, event_id, kind, detail, vendor_id, device_type, ios_version, created_at)",
  values: [String],
) async throws {
  let joined = values.joined(separator: ",\n")
  try await sql.execute("""
    INSERT INTO \(unsafeRaw: table) \(unsafeRaw: columns)
    VALUES \(unsafeRaw: joined)
  """)
}

private func formatTimestamp(_ date: Date) -> String {
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
  return formatter.string(from: date)
}

private func parseDetail(_ raw: String) -> ParsedDetail {
  var detail: String? = nil
  var deviceType = "iPhone"
  var iOSVersion = "unknown"
  var vendorId: UUID? = nil

  if let deviceRange = raw.range(of: ", device: `") {
    let beforeDevice = String(raw[..<deviceRange.lowerBound])
    if !beforeDevice.isEmpty {
      detail = beforeDevice
    }
  }

  if let match = raw.range(of: "device: `"),
     let end = raw[match.upperBound...].range(of: "`") {
    deviceType = String(raw[match.upperBound ..< end.lowerBound])
  }

  if let match = raw.range(of: "iOS: `"),
     let end = raw[match.upperBound...].range(of: "`") {
    iOSVersion = String(raw[match.upperBound ..< end.lowerBound])
  }

  if let match = raw.range(of: "vendorId: `"),
     let end = raw[match.upperBound...].range(of: "`") {
    let uuidString = String(raw[match.upperBound ..< end.lowerBound])
    vendorId = UUID(uuidString: uuidString)
  }

  return ParsedDetail(
    detail: detail,
    deviceType: deviceType,
    iOSVersion: iOSVersion,
    vendorId: vendorId,
  )
}

private func reconstructDetail(
  detail: String?,
  deviceType: String,
  iOSVersion: String,
  vendorId: UUID?,
) -> String {
  let vendorStr = vendorId?.uuidString.lowercased() ?? "(nil)"
  let prefix = detail.map { "\($0), " } ?? ""
  return "\(prefix)device: `\(deviceType)`, iOS: `\(iOSVersion)`, vendorId: `\(vendorStr)`"
}

private func escape(_ string: String) -> String {
  string.replacingOccurrences(of: "'", with: "''")
}

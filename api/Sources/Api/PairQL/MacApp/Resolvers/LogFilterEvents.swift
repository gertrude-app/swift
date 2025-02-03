import DuetSQL
import Gertie
import MacAppRoute
import PostgresKit

extension LogFilterEvents: Resolver {
  static func resolve(with input: Input, in context: UserContext) async throws -> Output {
    let deviceId = try await context.userDevice().id
    let events = try await context.db.create(input.events.map { event, count in
      InterestingEvent(
        eventId: event.id,
        kind: "event",
        context: "macapp-filter",
        computerUserId: deviceId,
        parentId: nil,
        detail: [event.detail, count > 1 ? "(\(count)x)" : nil]
          .compactMap { $0 }
          .joined(separator: " ")
      )
    })

    if input.bundleIds.isEmpty {
      return .success
    }

    let rows = try await context.db.customQuery(IdentifiedBundleIds.self)
    let identifiedBundleIds = Set(rows.map(\.bundleId))
    var bindings: [Postgres.Data] = []

    for (bundleId, count) in input.bundleIds {
      if !identifiedBundleIds.contains(bundleId) {
        bindings.append(.string(bundleId))
        bindings.append(.int(count))
      }
    }
    _ = try await context.db.customQuery(
      UpsertUnidentifiedApps.self,
      withBindings: bindings
    )

    if context.env.mode == .prod {
      for e in events {
        await with(dependency: \.slack)
          .sysLog("Macapp *filter* event: \(githubSearch(e.eventId)) \(e.detail ?? "")")
      }
    }

    return .success
  }
}

struct UpsertUnidentifiedApps: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let tableName = UnidentifiedApp.qualifiedTableName
    let count = UnidentifiedApp.columnName(.count)
    let bundleId = UnidentifiedApp.columnName(.bundleId)
    var stmt = SQL.Statement("""
    INSERT INTO \(tableName) (id, \(bundleId), \(count), created_at) VALUES (
    """)
    for i in (0 ..< bindings.count).striding(by: 2) {
      stmt.components.append(.sql("'\(UUID().lowercased)', "))
      stmt.components.append(.binding(bindings[i]))
      stmt.components.append(.sql(", "))
      stmt.components.append(.binding(bindings[i + 1]))
      stmt.components.append(.sql(", CURRENT_TIMESTAMP), ("))
    }
    stmt.components.removeLast()
    stmt.components.append(.sql(", CURRENT_TIMESTAMP)\n"))
    stmt.components.append(.sql("""
    ON CONFLICT (\(bundleId))
    DO UPDATE SET \(count) = \(tableName).\(count) + EXCLUDED.\(count)
    """))
    return stmt
  }
}

struct IdentifiedBundleIds: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    .init("""
    SELECT \(AppBundleId.columnName(.bundleId)) FROM \(AppBundleId.qualifiedTableName)
    """)
  }

  var bundleId: String
}

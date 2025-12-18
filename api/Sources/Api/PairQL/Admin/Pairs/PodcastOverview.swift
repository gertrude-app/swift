import DuetSQL
import PairQL

struct PodcastOverview: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Output: PairOutput {
    var totalInstalls: Int
    var successfulSubscriptions: Int
  }
}

extension PodcastOverview: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    let installs = try await context.db.customQuery(
      DistinctDeviceEventCount.self,
      withBindings: [.string("27c4f26a")],
    )
    let subscriptions = try await context.db.customQuery(
      DistinctDeviceEventCount.self,
      withBindings: [.string("a72104d7")],
    )

    return .init(
      totalInstalls: installs.first?.count ?? 0,
      successfulSubscriptions: subscriptions.first?.count ?? 0,
    )
  }
}

struct DistinctDeviceEventCount: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    var stmt = SQL.Statement("""
    SELECT COUNT(DISTINCT \(PodcastEvent.columnName(.installId))) AS count
    FROM \(PodcastEvent.qualifiedTableName)
    WHERE \(PodcastEvent.columnName(.eventId)) =
    """)
    if let eventId = bindings.first {
      stmt.components.append(.binding(eventId))
    }
    return stmt
  }

  var count: Int
}

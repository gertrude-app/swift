import DuetSQL
import PairQL

struct PodcastOverview: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Output: PairOutput {
    var totalInstalls: Int
    var successfulSubscriptions: Int
    var conversionRate: Double
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
    let pastTrial = try await context.db.customQuery(
      PastTrialInstallCount.self,
      withBindings: [.string("27c4f26a")],
    )

    let pastTrialInstallCount = pastTrial.first?.count ?? 0
    let subscriptionCount = subscriptions.first?.count ?? 0
    let rate = pastTrialInstallCount > 0
      ? (Double(subscriptionCount) / Double(pastTrialInstallCount) * 1000).rounded() / 10
      : 0.0

    return .init(
      totalInstalls: installs.first?.count ?? 0,
      successfulSubscriptions: subscriptionCount,
      conversionRate: rate,
    )
  }
}

private struct DistinctDeviceEventCount: CustomQueryable {
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

private struct PastTrialInstallCount: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    var stmt = SQL.Statement("""
    SELECT COUNT(DISTINCT \(PodcastEvent.columnName(.installId))) AS count
    FROM \(PodcastEvent.qualifiedTableName)
    WHERE
      \(PodcastEvent.columnName(.createdAt)) < NOW() - INTERVAL '30 days'
      AND \(PodcastEvent.columnName(.eventId)) =
    """)
    if let eventId = bindings.first {
      stmt.components.append(.binding(eventId))
    }
    return stmt
  }

  var count: Int
}

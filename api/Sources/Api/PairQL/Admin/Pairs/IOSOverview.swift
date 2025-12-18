import DuetSQL
import PairQL

struct IOSOverview: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Output: PairOutput {
    var firstLaunches: Int
    var authorizationSuccesses: Int
    var filterInstallSuccesses: Int
    var conversionRate: Double
  }
}

extension IOSOverview: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    let firstLaunchCount = try await InterestingEvent.query()
      .where(.eventId == "8d35f043")
      .count(in: context.db)

    let authCount = try await InterestingEvent.query()
      .where(.eventId == "4a0c585f")
      .count(in: context.db)

    let installCount = try await InterestingEvent.query()
      .where(.eventId == "adced334")
      .count(in: context.db)

    let conversionRate = firstLaunchCount > 0
      ? Double(installCount) / Double(firstLaunchCount) * 100
      : 0

    return .init(
      firstLaunches: firstLaunchCount,
      authorizationSuccesses: authCount,
      filterInstallSuccesses: installCount,
      conversionRate: conversionRate,
    )
  }
}

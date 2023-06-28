import DuetSQL
import PairQL

struct AllowingSignups: Pair {
  static var auth: ClientAuth = .none
}

// resolver

extension AllowingSignups: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    let allowedPerDay = Current.env.get("NUM_ALLOWED_SIGNUPS_PER_DAY").flatMap { Int($0) } ?? 10
    let todaysSignups = try await Current.db.query(Admin.self)
      .where(
        .subscriptionStatus |!=| [
          Admin.SubscriptionStatus.pendingEmailVerification,
          Admin.SubscriptionStatus.emailVerified,
        ]
      )
      .where(.createdAt >= .date(Calendar.current.startOfDay(for: Date())))
      .all()
    return Output(todaysSignups.count < allowedPerDay)
  }
}

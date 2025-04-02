import DuetSQL
import PairQL

struct CombinedUsersActivitySummaries: Pair {
  static let auth: ClientAuth = .parent
  typealias Input = [DateRange]
  typealias Output = [UserActivitySummaries.Day]
}

// resolver

extension CombinedUsersActivitySummaries: Resolver {
  static func resolve(
    with input: Input,
    in context: AdminContext
  ) async throws -> Output {
    try await UserActivitySummaries.days(
      dateRanges: input,
      userDeviceIds: context.userDevices().map(\.id),
      in: context.db
    )
  }
}

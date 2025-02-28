import Dependencies
import DuetSQL
import Gertie
import GertieIOS
import IOSRoute

extension DefaultBlockRules: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    try await IOSBlockRule.query()
      .where(.not(.isNull(.group)))
      .all(in: context.db)
      .filter { BlockGroup(rawValue: $0.group ?? "") != nil }
      .map(\.rule)
  }
}

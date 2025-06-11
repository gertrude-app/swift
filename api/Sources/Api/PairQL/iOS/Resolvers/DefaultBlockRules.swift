import Dependencies
import DuetSQL
import Gertie
import GertieIOS
import IOSRoute

extension DefaultBlockRules: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    try await IOSApp.BlockRule.query()
      .where(.not(.isNull(.groupId)))
      .all(in: context.db)
      .map(\.rule)
  }
}

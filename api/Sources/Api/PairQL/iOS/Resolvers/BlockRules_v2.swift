import Dependencies
import DuetSQL
import Gertie
import GertieIOS
import IOSRoute

extension BlockRules_v2: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    with(dependency: \.logger).info("BlockRules_v2: \(input)")
    return try await IOSApp.BlockRule.query()
      .where(.or(
        .not(.isNull(.group)) .&& .group |!=| input.disabledGroups.map { .string($0.rawValue) },
        .vendorId == (input.vendorId == .init(.zero) ? .init() : input.vendorId)
      ))
      .orderBy(.id, .asc)
      .all(in: context.db)
      .map(\.rule)
  }
}

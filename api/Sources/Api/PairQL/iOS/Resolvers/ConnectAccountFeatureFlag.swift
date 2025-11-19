import GertieIOS
import IOSRoute

extension ConnectAccountFeatureFlag: NoInputResolver {
  static func resolve(in ctx: Context) async throws -> Output {
    .init(isEnabled: false)
  }
}

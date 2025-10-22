import PodcastRoute

extension PodcastProducts: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    ["gertrude.am.yearly.permanent.access"]
  }
}

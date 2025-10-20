import PodcastRoute
import Vapor

extension PodcastRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {
    case .unauthed(let unauthed):
      switch unauthed {
      case .logPodcastEvent(let input):
        let output = try await LogPodcastEvent.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .podcastProducts:
        let output = try await PodcastProducts.resolve(in: context)
        return try await self.respond(with: output)
      case .createDatabaseUpload(let input):
        let output = try await CreateDatabaseUpload.resolve(with: input, in: context)
        return try await self.respond(with: output)
      }
    }
  }
}

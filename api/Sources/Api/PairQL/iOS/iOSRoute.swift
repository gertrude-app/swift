import IOSRoute
import Vapor

extension IOSRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {
    case .blockRules(let input):
      let output = try await BlockRules.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .logIOSEvent(let input):
      let output = try await LogIOSEvent.resolve(with: input, in: context)
      return try await self.respond(with: output)
    }
  }
}

import IOSRoute
import Vapor

extension IOSRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {
    case .blockRules(let input):
      let output = try await BlockRules.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .blockRules_v2(let input):
      let output = try await BlockRules_v2.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .defaultBlockRules(let input):
      let output = try await DefaultBlockRules.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .logIOSEvent(let input):
      let output = try await LogIOSEvent.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .recoveryDirective(let input):
      let output = try await RecoveryDirective.resolve(with: input, in: context)
      return try await self.respond(with: output)
    }
  }
}

import PairQL
import Vapor

enum UnauthedAdminRoute: PairRoute {
  case requestMagicLink(RequestAdminMagicLink.Input)
  case verifyMagicLink(VerifyAdminMagicLink.Input)

  nonisolated(unsafe) static let router = OneOf {
    Route(.case(Self.requestMagicLink)) {
      Operation(RequestAdminMagicLink.self)
      Body(.input(RequestAdminMagicLink.self))
    }
    Route(.case(Self.verifyMagicLink)) {
      Operation(VerifyAdminMagicLink.self)
      Body(.input(VerifyAdminMagicLink.self))
    }
  }
}

extension UnauthedAdminRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {
    case .requestMagicLink(let input):
      let output = try await RequestAdminMagicLink.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .verifyMagicLink(let input):
      let output = try await VerifyAdminMagicLink.resolve(with: input, in: context)
      return try await self.respond(with: output)
    }
  }
}

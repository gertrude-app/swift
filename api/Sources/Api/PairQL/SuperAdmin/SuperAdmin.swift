import PairQL
import Vapor

enum SuperAdminRoute: PairRoute {
  case authed(UUID, AuthedSuperAdminRoute)
}

enum AuthedSuperAdminRoute: PairRoute {
  case createRelease(CreateRelease.Input)

  static let router = OneOf {
    Route(/Self.createRelease) {
      Operation(CreateRelease.self)
      Body(.json(CreateRelease.Input.self))
    }
  }
}

extension SuperAdminRoute {
  static let router = OneOf {
    Route(/Self.authed) {
      Headers { Field("X-SuperAdminToken") { UUID.parser() } }
      AuthedSuperAdminRoute.router
    }
  }
}

extension SuperAdminRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    guard case .authed(let token, let authedRoute) = route,
          token.uuidString.lowercased() == Env.get("SUPER_ADMIN_TOKEN") else {
      throw Abort(.notFound)
    }

    switch authedRoute {
    case .createRelease(let input):
      let output = try await CreateRelease.resolve(with: input, in: context)
      return try await respond(with: output)
    }
  }
}

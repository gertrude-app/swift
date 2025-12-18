import PairQL
import Vapor

enum SuperAdminRoute: PairRoute {
  case authed(UUID, AuthedSuperAdminRoute)
}

enum AuthedSuperAdminRoute: PairRoute {
  case createDashAnnouncement(CreateDashAnnouncement.Input)
  case createRelease(CreateRelease.Input)

  nonisolated(unsafe) static let router = OneOf {
    Route(.case(Self.createDashAnnouncement)) {
      Operation(CreateDashAnnouncement.self)
      Body(.input(CreateDashAnnouncement.self))
    }
    Route(.case(Self.createRelease)) {
      Operation(CreateRelease.self)
      Body(.input(CreateRelease.self))
    }
  }
}

extension SuperAdminRoute {
  nonisolated(unsafe) static let router = OneOf {
    Route(.case(Self.authed)) {
      Headers { Field("X-SuperAdminToken") { UUID.parser() } }
      AuthedSuperAdminRoute.router
    }
  }
}

extension SuperAdminRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    guard case .authed(let token, let authedRoute) = route,
          let superAdminToken = context.env.get("SUPER_ADMIN_TOKEN"),
          token.uuidString.lowercased() == superAdminToken else {
      throw Abort(.notFound)
    }

    switch authedRoute {
    case .createDashAnnouncement(let input):
      let output = try await CreateDashAnnouncement.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .createRelease(let input):
      let output = try await CreateRelease.resolve(with: input, in: context)
      return try await self.respond(with: output)
    }
  }
}

import PairQL
import Vapor

enum SuperAdminRoute: PairRoute {
  case authed(UUID, AuthedSuperAdminRoute)
}

enum AuthedSuperAdminRoute: PairRoute {
  case createRelease(CreateRelease.Input)
  case queryAdmins
  case analyticsOverview
  case parentOverviews

  nonisolated(unsafe) static let router = OneOf {
    Route(.case(Self.createRelease)) {
      Operation(CreateRelease.self)
      Body(.input(CreateRelease.self))
    }
    Route(.case(Self.queryAdmins)) {
      Operation(QueryAdmins.self)
    }
    Route(.case(Self.analyticsOverview)) {
      Operation(AnalyticsOverview.self)
    }
    Route(.case(Self.parentOverviews)) {
      Operation(ParentOverviews.self)
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
          token.uuidString.lowercased() == superAdminToken
    else {
      throw Abort(.notFound)
    }

    switch authedRoute {
    case .createRelease(let input):
      let output = try await CreateRelease.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .queryAdmins:
      let output = try await QueryAdmins.resolve(in: context)
      return try await self.respond(with: output)
    case .analyticsOverview:
      let output = try await AnalyticsOverview.resolve(in: context)
      return try await self.respond(with: output)
    case .parentOverviews:
      let output = try await ParentOverviews.resolve(in: context)
      return try await self.respond(with: output)
    }
  }
}

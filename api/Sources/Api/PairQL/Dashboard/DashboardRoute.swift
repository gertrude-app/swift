import DuetSQL
import Foundation
import PairQL
import Vapor

enum DashboardRoute: PairRoute {
  case adminAuthed(UUID, AuthedAdminRoute)
  case unauthed(UnauthedRoute)
}

extension DashboardRoute {
  nonisolated(unsafe) static let router = OneOf {
    Route(.case(Self.adminAuthed)) {
      Headers { Field("X-AdminToken") { UUID.parser() } }
      AuthedAdminRoute.router
    }
    Route(.case(Self.unauthed)) {
      UnauthedRoute.router
    }
  }
}

extension DashboardRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {
    case .adminAuthed(let uuid, let parentRoute):
      let token = try await Parent.DashToken.query()
        .where(.value == uuid)
        .first(
          in: context.db,
          orThrow: context.error("8df93d61", .loggedOut, "Admin token not found")
        )

      let parent = try await Parent.query()
        .where(.id == token.parentId)
        .first(in: context.db)

      let parentContext = ParentContext(
        requestId: context.requestId,
        dashboardUrl: context.dashboardUrl,
        parent: parent,
        ipAddress: context.ipAddress
      )

      return try await AuthedAdminRoute.respond(to: parentRoute, in: parentContext)
    case .unauthed(let route):
      return try await UnauthedRoute.respond(to: route, in: context)
    }
  }
}

// helpers

extension Conversion {
  static func dashboardInput<P: Pair>(
    _ Pair: P.Type
  ) -> Self where Self == Conversions.JSON<P.Input> {
    .input(Pair, dateDecodingStrategy: .forgivingIso8601)
  }
}

extension JSONDecoder.DateDecodingStrategy {
  static let forgivingIso8601 = custom {
    let container = try $0.singleValueContainer()
    let string = try container.decode(String.self)
    if let date = Formatter.iso8601withFractionalSeconds().date(from: string)
      ?? Formatter.iso8601().date(from: string) {
      return date
    }
    throw DecodingError.dataCorruptedError(
      in: container,
      debugDescription: "Invalid date: \(string)"
    )
  }
}

extension Formatter {
  static func iso8601withFractionalSeconds() -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }

  static func iso8601() -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
  }
}

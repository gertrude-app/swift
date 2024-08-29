import DuetSQL
import Foundation
import PairQL
import Vapor

#if os(Linux)
  extension ISO8601DateFormatter: @unchecked Sendable {}
#endif

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
    case .adminAuthed(let uuid, let adminRoute):
      let token = try await Current.db.query(AdminToken.self)
        .where(.value == uuid)
        .first(orThrow: context.error("8df93d61", .loggedOut, "Admin token not found"))

      let admin = try await Current.db.query(Admin.self)
        .where(.id == token.adminId)
        .first()

      let adminContext = AdminContext(
        requestId: context.requestId,
        dashboardUrl: context.dashboardUrl,
        admin: admin,
        ipAddress: context.ipAddress
      )

      return try await AuthedAdminRoute.respond(to: adminRoute, in: adminContext)
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
    if let date = Formatter.iso8601withFractionalSeconds.date(from: string) ?? Formatter.iso8601
      .date(from: string) {
      return date
    }
    throw DecodingError.dataCorruptedError(
      in: container,
      debugDescription: "Invalid date: \(string)"
    )
  }
}

extension Formatter {
  static let iso8601withFractionalSeconds: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  static let iso8601: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
  }()
}

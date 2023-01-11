import DuetSQL
import Foundation
import PairQL
import TypescriptPairQL
import Vapor

enum DashboardRoute: PairRoute {
  case adminAuthed(UUID, AuthedAdminRoute)
  case unauthed(UnauthedRoute)
}

extension DashboardRoute {
  static let router = OneOf {
    Route(/Self.adminAuthed) {
      Headers { Field("X-AdminToken") { UUID.parser() } }
      AuthedAdminRoute.router
    }
    Route(/Self.unauthed) {
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
        admin: admin
      )

      return try await AuthedAdminRoute.respond(to: adminRoute, in: adminContext)
    case .unauthed(let route):
      return try await UnauthedRoute.respond(to: route, in: context)
    }
  }
}

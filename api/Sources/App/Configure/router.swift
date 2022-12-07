import GqlDashboard
import GqlMacOS
import URLRouting
import Vapor
import VaporRouting

public extension Configure {
  static func router(_ app: Application) {
    app.mount(GqlRoute.router) { _, route in
      try await GqlRoute.respond(to: route, in: Context())
    }
  }
}

enum GqlRoute: Equatable, RouteResponder {
  case dashboard(DashboardRoute)
  case macApp(MacAppRoute)

  static let router = OneOf {
    Route(.case(GqlRoute.macApp)) {
      Method.post
      Path { "gertieql" }
      Path { "macos-app" }
      MacAppRoute.router
    }
    Route(.case(GqlRoute.dashboard)) {
      Method.post
      Path { "gertieql" }
      Path { "dashboard" }
      DashboardRoute.router
    }
  }

  static func respond(to route: GqlRoute, in context: Context) async throws -> Response {
    let context = Context(request: .init())
    switch route {
    case .macApp(let appRoute):
      return try await MacAppRoute.respond(to: appRoute, in: context)
    case .dashboard(let dashboardRoute):
      return try await DashboardRoute.respond(to: dashboardRoute, in: context)
    }
  }
}

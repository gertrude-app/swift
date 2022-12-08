import GqlDashboard
import GqlMacOS
import URLRouting
import Vapor
import VaporRouting

public extension Configure {
  static func router(_ app: Application) throws {
    app.get("gertieql", "**") { request async throws -> Response in
      guard var requestData = URLRequestData(request: request),
            requestData.path.removeFirst() == "gertieql" else {
        throw Abort(.badRequest)
      }

      do {
        let route = try GqlRoute.router.parse(requestData)
        return try await GqlRoute.respond(to: route, in: Context())
      } catch {
        guard Env.mode == .dev else { throw error }
        return Response(status: .notFound, body: .init(string: "Routing \(error)"))
      }
    }
  }
}

enum GqlRoute: Equatable, RouteResponder {
  case dashboard(DashboardRoute)
  case macApp(MacAppRoute)

  static let router = OneOf {
    Route(.case(GqlRoute.macApp)) {
      Method.post
      Path { "macos-app" }
      MacAppRoute.router
    }
    Route(.case(GqlRoute.dashboard)) {
      Method.post
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

import MacAppRoute
import URLRouting
import Vapor

enum PairQLRoute: Equatable, RouteResponder {
  struct Context {
    let headers: HTTPHeaders
  }

  case dashboard(DashboardRoute)
  case macApp(MacAppRoute)

  static let router = OneOf {
    Route(.case(PairQLRoute.macApp)) {
      Method.post
      Path { "macos-app" }
      MacAppRoute.router
    }
    Route(.case(PairQLRoute.dashboard)) {
      Method.post
      Path { "dashboard" }
      DashboardRoute.router
    }
  }

  static func respond(to route: PairQLRoute, in context: Context) async throws -> Response {
    switch route {
    case .macApp(let appRoute):
      return try await MacAppRoute.respond(to: appRoute, in: .init())
    case .dashboard(let dashboardRoute):
      let dashboardUrl = context.headers.first(name: .xDashboardUrl) ?? Env.DASHBOARD_URL
      let dashboardContext = DashboardContext(dashboardUrl: dashboardUrl)
      return try await DashboardRoute.respond(to: dashboardRoute, in: dashboardContext)
    }
  }

  static func handler(_ request: Request) async throws -> Response {
    guard var requestData = URLRequestData(request: request),
          requestData.path.removeFirst() == "pairql" else {
      throw Abort(.badRequest)
    }

    do {
      let route = try PairQLRoute.router.parse(requestData)
      return try await PairQLRoute.respond(to: route, in: .init(headers: request.headers))
    } catch {
      guard Env.mode == .dev else { throw error }
      return Response(status: .notFound, body: .init(string: "Routing \(error)"))
    }
  }
}

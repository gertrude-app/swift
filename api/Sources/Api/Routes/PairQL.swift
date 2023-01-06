import MacAppRoute
import URLRouting
import Vapor
import VaporRouting

enum PairQLRoute: Equatable, RouteResponder {
  struct Context: ResolverContext {
    let requestId: String
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
      return try await MacAppRoute.respond(to: appRoute, in: .init(requestId: context.requestId))
    case .dashboard(let dashboardRoute):
      let dashboardContext = DashboardContext(
        requestId: context.requestId,
        dashboardUrl: context.headers.first(name: .xDashboardUrl) ?? Env.DASHBOARD_URL
      )
      return try await DashboardRoute.respond(to: dashboardRoute, in: dashboardContext)
    }
  }

  static func handler(_ request: Request) async throws -> Response {
    guard var requestData = URLRequestData(request: request),
          requestData.path.removeFirst() == "pairql" else {
      throw Abort(.badRequest)
    }

    let context = Context(requestId: request.id, headers: request.headers)
    do {
      let route = try PairQLRoute.router.parse(requestData)
      return try await PairQLRoute.respond(to: route, in: context)
    } catch {
      if "\(type(of: error))" == "ParsingError" {
        if Env.mode == .dev { print("PairQL routing \(error)") }
        return .init(PqlError(
          id: "0f5a25c9",
          requestId: context.requestId,
          type: .notFound,
          debugMessage: Env.mode == .dev ? "PairQL routing \(error)" : "PairQL route not found",
          showContactSupport: true
        ))
      } else if let pqlError = error as? PqlError {
        return .init(pqlError)
      } else if let convertible = error as? PqlErrorConvertible {
        return .init(convertible.pqlError(in: context))
      } else {
        print(type(of: error), error)
        throw error
      }
      // guard Env.mode == .dev else { throw error }
      // print(String(describing: error))
      // return Response(status: .notFound, body: .init(string: "Routing \(error)"))
    }
  }
}

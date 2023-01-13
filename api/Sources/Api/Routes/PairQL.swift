import MacAppRoute
import URLRouting
import Vapor
import VaporRouting

struct Context: ResolverContext {
  let requestId: String
  let dashboardUrl: String
}

enum PairQLRoute: Equatable, RouteResponder {
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
      return try await MacAppRoute.respond(to: appRoute, in: context)
    case .dashboard(let dashboardRoute):
      return try await DashboardRoute.respond(to: dashboardRoute, in: context)
    }
  }

  static func handler(_ request: Request) async throws -> Response {
    guard var requestData = URLRequestData(request: request),
          requestData.path.removeFirst() == "pairql" else {
      throw Abort(.badRequest)
    }

    let context = Context(requestId: request.id, dashboardUrl: request.dashboardUrl)
    do {
      let route = try PairQLRoute.router.parse(requestData)
      logOperation(route, request)
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
    }
  }
}

// helpers

private func logOperation(_ route: PairQLRoute, _ request: Request) {
  switch route {
  case .macApp:
    let operation = request.parameters.get("operation") ?? ""
    Current.logger
      .notice("PairQL request: \("MacApp".magenta) \(operation.yellow)")
  case .dashboard:
    let operation = request.parameters.get("operation") ?? ""
    Current.logger
      .notice("PairQL request: \("Dashboard".green) \(operation.yellow)")
  }
}

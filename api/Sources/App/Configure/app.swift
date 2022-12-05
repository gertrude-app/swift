import GertieQL
import Vapor
import VaporRouting

public enum Configure {
  public static func app(_ app: Application) throws {
    Configure.env(app)
    Configure.database(app)
    Configure.middleware(app)
    try Configure.migrations(app)
  }
}

func routeHandler(request: Request, route: GertieQL.Route) async throws -> Response {
  let context = Context(request: .init())
  switch route {
  case .macApp(let appRoute):
    return try await MacApp.respond(to: appRoute, in: context)
  case .dashboard(let dashboardRoute):
    return try await Dashboard.respond(to: dashboardRoute, in: context)
  }
}

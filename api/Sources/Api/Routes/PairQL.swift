import Dependencies
import IOSRoute
import MacAppRoute
import URLRouting
import Vapor
import VaporRouting

struct Context: ResolverContext {
  let requestId: String
  let dashboardUrl: String
  let ipAddress: String?

  @Dependency(\.db) var db
  @Dependency(\.env) var env
}

enum PairQLRoute: Equatable, RouteResponder {
  case dashboard(DashboardRoute)
  case macApp(MacAppRoute)
  case superAdmin(SuperAdminRoute)
  case iOS(IOSRoute)

  nonisolated(unsafe) static let router = OneOf {
    Route(.case(PairQLRoute.macApp)) {
      Method("POST")
      Path { "macos-app" }
      MacAppRoute.router
    }
    Route(.case(PairQLRoute.iOS)) {
      Method("POST")
      Path { "ios-app" }
      IOSRoute.router
    }
    Route(.case(PairQLRoute.dashboard)) {
      Method("POST")
      Path { "dashboard" }
      DashboardRoute.router
    }
    Route(.case(PairQLRoute.superAdmin)) {
      Method("POST")
      Path { "super-admin" }
      SuperAdminRoute.router
    }
  }

  static func respond(to route: PairQLRoute, in context: Context) async throws -> Response {
    switch route {
    case .macApp(let appRoute):
      try await MacAppRoute.respond(to: appRoute, in: context)
    case .dashboard(let dashboardRoute):
      try await DashboardRoute.respond(to: dashboardRoute, in: context)
    case .superAdmin(let superAdminRoute):
      try await SuperAdminRoute.respond(to: superAdminRoute, in: context)
    case .iOS(let iosAppRoute):
      try await IOSRoute.respond(to: iosAppRoute, in: context)
    }
  }

  @Sendable static func handler(_ request: Request) async throws -> Response {
    guard var requestData = URLRequestData(request: request),
          requestData.path.removeFirst() == "pairql" else {
      throw Abort(.badRequest)
    }

    let context = Context(
      requestId: request.id,
      dashboardUrl: request.dashboardUrl,
      ipAddress: request.ipAddress
    )
    do {
      let route = try PairQLRoute.router.parse(requestData)
      let start = Date()
      let output = try await PairQLRoute.respond(to: route, in: context)
      logOperation(route, request, Date().timeIntervalSince(start))
      return output
    } catch {
      if "\(type(of: error))" == "ParsingError" {
        switch request.context.env.mode {
        case .prod:
          await slackPairQLRouteNotFound(request, error)
        case .dev:
          print("PairQL parsing \(error)")
        case .staging, .test:
          break
        }
        return .init(PqlError(
          id: "0f5a25c9",
          requestId: context.requestId,
          type: .notFound,
          debugMessage: request.context.env.mode == .dev
            ? "PairQL routing \(error)"
            : "PairQL route not found",
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

private func logOperation(_ route: PairQLRoute, _ request: Request, _ duration: TimeInterval) {
  let operation = "\(request.parameters.get("operation") ?? "")".yellow
  var elapsed = ""
  switch duration {
  case 0.0 ..< 1.0:
    elapsed = "(\(Int(duration * 1000)) ms)".dim
  default:
    elapsed = "(\(String(format: "%.2f", duration)) sec)".red
  }
  switch route {
  case .macApp:
    request.logger
      .notice("PairQL request: \("MacApp".magenta) \(operation) \(elapsed)")
  case .dashboard:
    request.logger
      .notice("PairQL request: \("Dashboard".green) \(operation) \(elapsed)")
  case .superAdmin:
    request.logger
      .notice("PairQL request: \("SuperAdmin".cyan) \(operation) \(elapsed)")
  case .iOS:
    request.logger
      .notice("PairQL request: \("iOS".blue) \(operation) \(elapsed)")
  }
}

private func slackPairQLRouteNotFound(_ request: Request, _ error: Error) async {
  let domain = request.parameters.get("domain") ?? ""
  let operation = request.parameters.get("operation") ?? ""

  // legacy removed pairs, these should error for non-upgraded macapps
  if [
    "RefreshRules",
    "CreateSuspendFilterRequest",
    "GetAccountStatus",
    "GetUserData",
    "CreateUnlockRequests_v2",
    "LatestAppVersion",
  ].contains(operation) {
    return
  }

  try? await with(dependency: \.slack).error("""
  *PairQL parsing error:*
  domain: `\(domain)`
  operation: `\(operation)`
  body:
  ```
  \(request.collectedBody() ?? "(nil)")
  ```
  headers:
  ```
  \(request.headers.debugDescription)
  ```
  error:
  ```
  \(error)
  ```
  """)
}

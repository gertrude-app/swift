import GqlDashboard
import Vapor

extension DashboardRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {
    case .placeholder:
      fatalError()
    }
  }
}

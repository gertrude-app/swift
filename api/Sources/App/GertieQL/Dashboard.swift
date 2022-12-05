import Vapor

extension Dashboard: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {
    case .placeholder:
      fatalError()
    }
  }
}

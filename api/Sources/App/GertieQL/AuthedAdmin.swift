import DuetSQL
import GqlDashboard
import Vapor

extension AuthedAdminRoute: RouteResponder {
  struct Context {
    let request: App.Context.Request
    let admin: Admin
  }

  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {
    case .getUser(let uuid):
      let output = try await GetUser.resolve(for: uuid, in: context)
      return try await respond(with: output)
    }
  }
}

extension GetUser: PairResolver {
  static func resolve(
    for input: UUID,
    in context: AuthedAdminRoute.Context
  ) async throws -> Output {
    fatalError()
  }
}

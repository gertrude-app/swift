import DashboardRoute
import Vapor

struct AdminContext {
  let request: Context.Request
  let admin: Admin
}

extension AuthedAdminRoute: RouteResponder {
  static func respond(to route: Self, in context: AdminContext) async throws -> Response {
    switch route {
    case .getUser(let uuid):
      let output = try await GetUser.resolve(for: uuid, in: context)
      return try await respond(with: output)
    case .getUsers:
      let output = try await GetUsers.resolve(in: context)
      return try await respond(with: output)
    case .saveUser(let input):
      let output = try await SaveUser.resolve(for: input, in: context)
      return try await respond(with: output)
    case .deleteUser(let uuid):
      let output = try await DeleteUser.resolve(for: uuid, in: context)
      return try await respond(with: output)
    }
  }
}

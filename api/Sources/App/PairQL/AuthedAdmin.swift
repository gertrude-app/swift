import DashboardRoute
import DuetSQL
import Vapor

struct AdminContext {
  let dashboardUrl: String
  let admin: Admin

  func verifiedUser(from uuid: UUID) async throws -> User {
    try await Current.db.query(User.self)
      .where(.id == uuid)
      .where(.adminId == admin.id)
      .first()
  }
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
    case .getUserActivityDays(let input):
      let output = try await GetUserActivityDays.resolve(for: input, in: context)
      return try await respond(with: output)
    }
  }
}

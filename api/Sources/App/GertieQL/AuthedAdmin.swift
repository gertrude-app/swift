import DashboardRoute
import DuetSQL
import Vapor

// typealias AdminContext = AuthedAdminRoute.Context

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
    }
  }
}

extension GetUser: PairResolver {
  static func resolve(for id: UUID, in context: AdminContext) async throws -> Output {
    let user = try await Current.db.query(User.self)
      .where(.id == id)
      .where(.adminId == context.admin.id)
      .first()
    return Output(
      id: id,
      name: user.name,
      keyloggingEnabled: user.keyloggingEnabled,
      screenshotsEnabled: user.screenshotsEnabled,
      screenshotsResolution: user.screenshotsResolution,
      screenshotsFrequency: user.screenshotsFrequency,
      createdAt: user.createdAt
    )
  }
}

extension GetUsers: NoInputPairResolver {
  static func resolve(in context: AdminContext) async throws -> Output {
    let users = try await Current.db.query(User.self)
      .where(.adminId == context.admin.id)
      .all()
    return users.map { user in
      GetUser.Output(
        id: user.id.rawValue,
        name: user.name,
        keyloggingEnabled: user.keyloggingEnabled,
        screenshotsEnabled: user.screenshotsEnabled,
        screenshotsResolution: user.screenshotsResolution,
        screenshotsFrequency: user.screenshotsFrequency,
        createdAt: user.createdAt
      )
    }
  }
}

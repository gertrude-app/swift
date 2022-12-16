import DuetSQL
import PairQL
import Vapor

enum AuthedAdminRoute: PairRoute {
  case getUser(GetUser.Input)
  case getUsers
  case saveUser(SaveUser.Input)
  case deleteUser(DeleteUser.Input)
  case getUserActivityDays(GetUserActivityDays.Input)
}

extension AuthedAdminRoute {
  static let router = OneOf {
    Route(/Self.getUser) {
      Operation(GetUser.self)
      Body(.json(GetUser.Input.self))
    }
    Route(/Self.getUsers) {
      Operation(GetUsers.self)
    }
    Route(/Self.saveUser) {
      Operation(SaveUser.self)
      Body(.json(SaveUser.Input.self))
    }
    Route(/Self.deleteUser) {
      Operation(DeleteUser.self)
      Body(.json(DeleteUser.Input.self))
    }
    Route(/Self.getUserActivityDays) {
      Operation(GetUserActivityDays.self)
      Body(.json(GetUserActivityDays.Input.self))
    }
  }
}

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
      let output = try await GetUser.resolve(with: uuid, in: context)
      return try await respond(with: output)
    case .getUsers:
      let output = try await GetUsers.resolve(in: context)
      return try await respond(with: output)
    case .saveUser(let input):
      let output = try await SaveUser.resolve(with: input, in: context)
      return try await respond(with: output)
    case .deleteUser(let uuid):
      let output = try await DeleteUser.resolve(with: uuid, in: context)
      return try await respond(with: output)
    case .getUserActivityDays(let input):
      let output = try await GetUserActivityDays.resolve(with: input, in: context)
      return try await respond(with: output)
    }
  }
}

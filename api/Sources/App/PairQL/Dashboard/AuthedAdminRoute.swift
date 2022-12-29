import DuetSQL
import PairQL
import Vapor

enum AuthedAdminRoute: PairRoute {
  case getAdmin
  case getUser(GetUser.Input)
  case getUsers
  case saveUser(SaveUser.Input)
  case deleteUser(DeleteUser.Input)
  case getUserActivityDays(GetUserActivityDays.Input)
  case getUserActivityDay(GetUserActivityDay.Input)
  case createBillingPortalSession
  case createPendingAppConnection(CreatePendingAppConnection.Input)
}

extension AuthedAdminRoute {
  static let router = OneOf {
    Route(/Self.getUser) {
      Operation(GetUser.self)
      Body(.json(GetUser.Input.self))
    }
    Route(/Self.getAdmin) {
      Operation(GetAdmin.self)
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
    Route(/Self.getUserActivityDay) {
      Operation(GetUserActivityDay.self)
      Body(.json(GetUserActivityDay.Input.self))
    }
    Route(/Self.createBillingPortalSession) {
      Operation(CreateBillingPortalSession.self)
    }
    Route(/Self.createPendingAppConnection) {
      Operation(CreatePendingAppConnection.self)
      Body(.json(CreatePendingAppConnection.Input.self))
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
    case .createBillingPortalSession:
      let output = try await CreateBillingPortalSession.resolve(in: context)
      return try await respond(with: output)
    case .createPendingAppConnection(let input):
      let output = try await CreatePendingAppConnection.resolve(with: input, in: context)
      return try await respond(with: output)
    case .getUserActivityDay(let input):
      let output = try await GetUserActivityDay.resolve(with: input, in: context)
      return try await respond(with: output)
    case .getAdmin:
      let output = try await GetAdmin.resolve(in: context)
      return try await respond(with: output)
    }
  }
}

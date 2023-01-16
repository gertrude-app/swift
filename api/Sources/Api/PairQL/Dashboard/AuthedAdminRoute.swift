import DuetSQL
import PairQL
import Vapor

struct AdminContext: ResolverContext {
  let requestId: String
  let dashboardUrl: String
  let admin: Admin

  @discardableResult
  func verifiedUser(from id: User.Id) async throws -> User {
    try await Current.db.query(User.self)
      .where(.id == id)
      .where(.adminId == admin.id)
      .first()
  }
}

enum AuthedAdminRoute: PairRoute {
  case confirmPendingNotificationMethod(ConfirmPendingNotificationMethod.Input)
  case createBillingPortalSession
  case createPendingAppConnection(CreatePendingAppConnection.Input)
  case createPendingNotificationMethod(CreatePendingNotificationMethod.Input)
  case deleteActivityItems(DeleteActivityItems.Input)
  case deleteEntity(DeleteEntity.Input)
  case getAdmin
  case getAdminKeychain(GetAdminKeychain.Input)
  case getAdminKeychains
  case getDashboardWidgets
  case getIdentifiedApps
  case getSelectableKeychains
  case getSuspendFilterRequest(GetSuspendFilterRequest.Input)
  case getUnlockRequest(GetUnlockRequest.Input)
  case getUser(GetUser.Input)
  case getUserActivityDay(GetUserActivityDay.Input)
  case getUserActivityDays(GetUserActivityDays.Input)
  case getUsers
  case getUserUnlockRequests(GetUserUnlockRequests.Input)
  case saveKey(SaveKey.Input)
  case saveKeychain(SaveKeychain.Input)
  case saveNotification_v0(SaveNotification_v0.Input)
  case saveUser(SaveUser.Input)
  case updateSuspendFilterRequest(UpdateSuspendFilterRequest.Input)
  case updateUnlockRequest(UpdateUnlockRequest.Input)
}

extension AuthedAdminRoute {
  static let router = OneOf {
    OneOf {
      Route(/Self.confirmPendingNotificationMethod) {
        Operation(ConfirmPendingNotificationMethod.self)
        Body(.json(ConfirmPendingNotificationMethod.Input.self))
      }
      Route(/Self.createBillingPortalSession) {
        Operation(CreateBillingPortalSession.self)
      }
      Route(/Self.createPendingAppConnection) {
        Operation(CreatePendingAppConnection.self)
        Body(.json(CreatePendingAppConnection.Input.self))
      }
      Route(/Self.createPendingNotificationMethod) {
        Operation(CreatePendingNotificationMethod.self)
        Body(.json(CreatePendingNotificationMethod.Input.self))
      }
      Route(/Self.deleteActivityItems) {
        Operation(DeleteActivityItems.self)
        Body(.json(DeleteActivityItems.Input.self))
      }
      Route(/Self.deleteEntity) {
        Operation(DeleteEntity.self)
        Body(.json(DeleteEntity.Input.self))
      }
      Route(/Self.getAdmin) {
        Operation(GetAdmin.self)
      }
      Route(/Self.getAdminKeychain) {
        Operation(GetAdminKeychain.self)
        Body(.json(GetAdminKeychain.Input.self))
      }
      Route(/Self.getAdminKeychains) {
        Operation(GetAdminKeychains.self)
      }
      Route(/Self.getDashboardWidgets) {
        Operation(GetDashboardWidgets.self)
      }
    }
    OneOf {
      Route(/Self.getIdentifiedApps) {
        Operation(GetIdentifiedApps.self)
      }
      Route(/Self.getSelectableKeychains) {
        Operation(GetSelectableKeychains.self)
      }
      Route(/Self.getSuspendFilterRequest) {
        Operation(GetSuspendFilterRequest.self)
        Body(.json(GetSuspendFilterRequest.Input.self))
      }
      Route(/Self.getUnlockRequest) {
        Operation(GetUnlockRequest.self)
        Body(.json(GetUnlockRequest.Input.self))
      }
      Route(/Self.getUser) {
        Operation(GetUser.self)
        Body(.json(GetUser.Input.self))
      }
      Route(/Self.getUserActivityDays) {
        Operation(GetUserActivityDays.self)
        Body(.json(GetUserActivityDays.Input.self))
      }
      Route(/Self.getUserActivityDay) {
        Operation(GetUserActivityDay.self)
        Body(.json(GetUserActivityDay.Input.self))
      }
      Route(/Self.getUsers) {
        Operation(GetUsers.self)
      }
      Route(/Self.getUserUnlockRequests) {
        Operation(GetUserUnlockRequests.self)
        Body(.json(GetUserUnlockRequests.Input.self))
      }
      Route(/Self.saveKey) {
        Operation(SaveKey.self)
        Body(.json(SaveKey.Input.self))
      }
    }
    OneOf {
      Route(/Self.saveKeychain) {
        Operation(SaveKeychain.self)
        Body(.json(SaveKeychain.Input.self))
      }
      Route(/Self.saveNotification_v0) {
        Operation(SaveNotification_v0.self)
        Body(.json(SaveNotification_v0.Input.self))
      }
      Route(/Self.saveUser) {
        Operation(SaveUser.self)
        Body(.json(SaveUser.Input.self))
      }
      Route(/Self.updateSuspendFilterRequest) {
        Operation(UpdateSuspendFilterRequest.self)
        Body(.json(UpdateSuspendFilterRequest.Input.self))
      }
      Route(/Self.updateUnlockRequest) {
        Operation(UpdateUnlockRequest.self)
        Body(.json(UpdateUnlockRequest.Input.self))
      }
    }
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
    case .deleteEntity(let input):
      let output = try await DeleteEntity.resolve(with: input, in: context)
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
    case .saveNotification_v0(let input):
      let output = try await SaveNotification_v0.resolve(with: input, in: context)
      return try await respond(with: output)
    case .getIdentifiedApps:
      let output = try await GetIdentifiedApps.resolve(in: context)
      return try await respond(with: output)
    case .getDashboardWidgets:
      let output = try await GetDashboardWidgets.resolve(in: context)
      return try await respond(with: output)
    case .getSelectableKeychains:
      let output = try await GetSelectableKeychains.resolve(in: context)
      return try await respond(with: output)
    case .getAdminKeychains:
      let output = try await GetAdminKeychains.resolve(in: context)
      return try await respond(with: output)
    case .getAdminKeychain(let input):
      let output = try await GetAdminKeychain.resolve(with: input, in: context)
      return try await respond(with: output)
    case .saveKeychain(let input):
      let output = try await SaveKeychain.resolve(with: input, in: context)
      return try await respond(with: output)
    case .confirmPendingNotificationMethod(let input):
      let output = try await ConfirmPendingNotificationMethod.resolve(with: input, in: context)
      return try await respond(with: output)
    case .getUnlockRequest(let input):
      let output = try await GetUnlockRequest.resolve(with: input, in: context)
      return try await respond(with: output)
    case .getUserUnlockRequests(let input):
      let output = try await GetUserUnlockRequests.resolve(with: input, in: context)
      return try await respond(with: output)
    case .getSuspendFilterRequest(let input):
      let output = try await GetSuspendFilterRequest.resolve(with: input, in: context)
      return try await respond(with: output)
    case .createPendingNotificationMethod(let input):
      let output = try await CreatePendingNotificationMethod.resolve(with: input, in: context)
      return try await respond(with: output)
    case .updateUnlockRequest(let input):
      let output = try await UpdateUnlockRequest.resolve(with: input, in: context)
      return try await respond(with: output)
    case .updateSuspendFilterRequest(let input):
      let output = try await UpdateSuspendFilterRequest.resolve(with: input, in: context)
      return try await respond(with: output)
    case .saveKey(let input):
      let output = try await SaveKey.resolve(with: input, in: context)
      return try await respond(with: output)
    case .deleteActivityItems(let input):
      let output = try await DeleteActivityItems.resolve(with: input, in: context)
      return try await respond(with: output)
    }
  }
}
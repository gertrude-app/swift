import DuetSQL
import PairQL
import Vapor

enum AuthedAdminRoute: PairRoute {
  case confirmPendingNotificationMethod(ConfirmPendingNotificationMethod.Input)
  case createPendingAppConnection(CreatePendingAppConnection.Input)
  case createPendingNotificationMethod(CreatePendingNotificationMethod.Input)
  case decideFilterSuspensionRequest(DecideFilterSuspensionRequest.Input)
  case deleteActivityItems_v2(DeleteActivityItems_v2.Input)
  case deleteEntity(DeleteEntity.Input)
  case getAdmin
  case getAdminKeychain(GetAdminKeychain.Input)
  case getAdminKeychains
  case getDashboardWidgets
  case getDevice(GetDevice.Input)
  case getDevices
  case getIdentifiedApps
  case getSelectableKeychains
  case getSuspendFilterRequest(GetSuspendFilterRequest.Input)
  case getUnlockRequest(GetUnlockRequest.Input)
  case getUnlockRequests
  case getUser(GetUser.Input)
  case handleCheckoutCancel(HandleCheckoutCancel.Input)
  case handleCheckoutSuccess(HandleCheckoutSuccess.Input)
  case latestAppVersions
  case logEvent(LogEvent.Input)
  case userActivityFeed(UserActivityFeed.Input)
  case userActivitySummaries(UserActivitySummaries.Input)
  case combinedUsersActivityFeed(CombinedUsersActivityFeed.Input)
  case combinedUsersActivitySummaries(CombinedUsersActivitySummaries.Input)
  case getUsers
  case getUserUnlockRequests(GetUserUnlockRequests.Input)
  case saveDevice(SaveDevice.Input)
  case saveKey(SaveKey.Input)
  case saveKeychain(SaveKeychain.Input)
  case saveNotification(SaveNotification.Input)
  case saveUser(SaveUser.Input)
  case stripeUrl
  case updateUnlockRequest(UpdateUnlockRequest.Input)
}

extension AuthedAdminRoute {
  static let router: AnyParserPrinter<URLRequestData, AuthedAdminRoute> = OneOf {
    Route(/Self.confirmPendingNotificationMethod) {
      Operation(ConfirmPendingNotificationMethod.self)
      Body(.dashboardInput(ConfirmPendingNotificationMethod.self))
    }
    Route(/Self.createPendingAppConnection) {
      Operation(CreatePendingAppConnection.self)
      Body(.dashboardInput(CreatePendingAppConnection.self))
    }
    Route(/Self.createPendingNotificationMethod) {
      Operation(CreatePendingNotificationMethod.self)
      Body(.dashboardInput(CreatePendingNotificationMethod.self))
    }
    Route(/Self.decideFilterSuspensionRequest) {
      Operation(DecideFilterSuspensionRequest.self)
      Body(.dashboardInput(DecideFilterSuspensionRequest.self))
    }
    Route(/Self.deleteActivityItems_v2) {
      Operation(DeleteActivityItems_v2.self)
      Body(.dashboardInput(DeleteActivityItems_v2.self))
    }
    Route(/Self.deleteEntity) {
      Operation(DeleteEntity.self)
      Body(.dashboardInput(DeleteEntity.self))
    }
    Route(/Self.getAdmin) {
      Operation(GetAdmin.self)
    }
    Route(/Self.getAdminKeychain) {
      Operation(GetAdminKeychain.self)
      Body(.dashboardInput(GetAdminKeychain.self))
    }
    Route(/Self.getAdminKeychains) {
      Operation(GetAdminKeychains.self)
    }
    Route(/Self.getDashboardWidgets) {
      Operation(GetDashboardWidgets.self)
    }
    Route(/Self.getDevice) {
      Operation(GetDevice.self)
      Body(.dashboardInput(GetDevice.self))
    }
    Route(/Self.getDevices) {
      Operation(GetDevices.self)
    }
    Route(/Self.getIdentifiedApps) {
      Operation(GetIdentifiedApps.self)
    }
    Route(/Self.getSelectableKeychains) {
      Operation(GetSelectableKeychains.self)
    }
    Route(/Self.getSuspendFilterRequest) {
      Operation(GetSuspendFilterRequest.self)
      Body(.dashboardInput(GetSuspendFilterRequest.self))
    }
    Route(/Self.getUnlockRequest) {
      Operation(GetUnlockRequest.self)
      Body(.dashboardInput(GetUnlockRequest.self))
    }
    Route(/Self.getUnlockRequests) {
      Operation(GetUnlockRequests.self)
    }
    Route(/Self.getUser) {
      Operation(GetUser.self)
      Body(.dashboardInput(GetUser.self))
    }
    Route(/Self.handleCheckoutCancel) {
      Operation(HandleCheckoutCancel.self)
      Body(.dashboardInput(HandleCheckoutCancel.self))
    }
    Route(/Self.handleCheckoutSuccess) {
      Operation(HandleCheckoutSuccess.self)
      Body(.dashboardInput(HandleCheckoutSuccess.self))
    }
    Route(/Self.logEvent) {
      Operation(LogEvent.self)
      Body(.dashboardInput(LogEvent.self))
    }
    Route(/Self.userActivitySummaries) {
      Operation(UserActivitySummaries.self)
      Body(.dashboardInput(UserActivitySummaries.self))
    }
    Route(/Self.userActivityFeed) {
      Operation(UserActivityFeed.self)
      Body(.dashboardInput(UserActivityFeed.self))
    }
    Route(/Self.combinedUsersActivityFeed) {
      Operation(CombinedUsersActivityFeed.self)
      Body(.dashboardInput(CombinedUsersActivityFeed.self))
    }
    Route(/Self.getUsers) {
      Operation(GetUsers.self)
    }
    Route(/Self.getUserUnlockRequests) {
      Operation(GetUserUnlockRequests.self)
      Body(.dashboardInput(GetUserUnlockRequests.self))
    }
    Route(/Self.latestAppVersions) {
      Operation(LatestAppVersions.self)
    }
    Route(/Self.saveDevice) {
      Operation(SaveDevice.self)
      Body(.dashboardInput(SaveDevice.self))
    }
    Route(/Self.saveKey) {
      Operation(SaveKey.self)
      Body(.dashboardInput(SaveKey.self))
    }
    Route(/Self.saveKeychain) {
      Operation(SaveKeychain.self)
      Body(.dashboardInput(SaveKeychain.self))
    }
    Route(/Self.saveNotification) {
      Operation(SaveNotification.self)
      Body(.dashboardInput(SaveNotification.self))
    }
    Route(/Self.saveUser) {
      Operation(SaveUser.self)
      Body(.dashboardInput(SaveUser.self))
    }
    Route(/Self.stripeUrl) {
      Operation(StripeUrl.self)
    }
    Route(/Self.updateUnlockRequest) {
      Operation(UpdateUnlockRequest.self)
      Body(.dashboardInput(UpdateUnlockRequest.self))
    }
    Route(/Self.combinedUsersActivitySummaries) {
      Operation(CombinedUsersActivitySummaries.self)
      Body(.dashboardInput(CombinedUsersActivitySummaries.self))
    }
  }
  .eraseToAnyParserPrinter()
}

extension AuthedAdminRoute: RouteResponder {
  static func respond(to route: Self, in context: AdminContext) async throws -> Response {
    switch route {
    case .getUser(let uuid):
      let output = try await GetUser.resolve(with: uuid, in: context)
      return try await self.respond(with: output)
    case .getUsers:
      let output = try await GetUsers.resolve(in: context)
      return try await self.respond(with: output)
    case .saveUser(let input):
      let output = try await SaveUser.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .deleteEntity(let input):
      let output = try await DeleteEntity.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .userActivitySummaries(let input):
      let output = try await UserActivitySummaries.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .createPendingAppConnection(let input):
      let output = try await CreatePendingAppConnection.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .decideFilterSuspensionRequest(let input):
      let output = try await DecideFilterSuspensionRequest.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .userActivityFeed(let input):
      let output = try await UserActivityFeed.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .combinedUsersActivityFeed(let input):
      let output = try await CombinedUsersActivityFeed.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .combinedUsersActivitySummaries(let input):
      let output = try await CombinedUsersActivitySummaries.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getAdmin:
      let output = try await GetAdmin.resolve(in: context)
      return try await self.respond(with: output)
    case .logEvent(let input):
      let output = try await LogEvent.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .saveDevice(let input):
      let output = try await SaveDevice.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .saveNotification(let input):
      let output = try await SaveNotification.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getIdentifiedApps:
      let output = try await GetIdentifiedApps.resolve(in: context)
      return try await self.respond(with: output)
    case .getDashboardWidgets:
      let output = try await GetDashboardWidgets.resolve(in: context)
      return try await self.respond(with: output)
    case .getDevice(let input):
      let output = try await GetDevice.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getDevices:
      let output = try await GetDevices.resolve(in: context)
      return try await self.respond(with: output)
    case .getSelectableKeychains:
      let output = try await GetSelectableKeychains.resolve(in: context)
      return try await self.respond(with: output)
    case .getAdminKeychains:
      let output = try await GetAdminKeychains.resolve(in: context)
      return try await self.respond(with: output)
    case .getAdminKeychain(let input):
      let output = try await GetAdminKeychain.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .handleCheckoutCancel(let input):
      let output = try await HandleCheckoutCancel.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .handleCheckoutSuccess(let input):
      let output = try await HandleCheckoutSuccess.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .latestAppVersions:
      let output = try await LatestAppVersions.resolve(in: context)
      return try await self.respond(with: output)
    case .saveKeychain(let input):
      let output = try await SaveKeychain.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .confirmPendingNotificationMethod(let input):
      let output = try await ConfirmPendingNotificationMethod.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getUnlockRequest(let input):
      let output = try await GetUnlockRequest.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getUnlockRequests:
      let output = try await GetUnlockRequests.resolve(in: context)
      return try await self.respond(with: output)
    case .getUserUnlockRequests(let input):
      let output = try await GetUserUnlockRequests.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getSuspendFilterRequest(let input):
      let output = try await GetSuspendFilterRequest.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .createPendingNotificationMethod(let input):
      let output = try await CreatePendingNotificationMethod.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .updateUnlockRequest(let input):
      let output = try await UpdateUnlockRequest.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .saveKey(let input):
      let output = try await SaveKey.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .stripeUrl:
      let output = try await StripeUrl.resolve(in: context)
      return try await self.respond(with: output)
    case .deleteActivityItems_v2(let input):
      let output = try await DeleteActivityItems_v2.resolve(with: input, in: context)
      return try await self.respond(with: output)
    }
  }
}

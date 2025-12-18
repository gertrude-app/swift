import DuetSQL
import PairQL
import Vapor

enum AuthedParentRoute: PairRoute {
  case confirmPendingNotificationMethod(ConfirmPendingNotificationMethod.Input)
  case createPendingAppConnection(CreatePendingAppConnection.Input)
  case createPendingNotificationMethod(CreatePendingNotificationMethod.Input)
  case dashboardWidgets
  case decideFilterSuspensionRequest(DecideFilterSuspensionRequest.Input)
  case deleteActivityItems_v2(DeleteActivityItems_v2.Input)
  case deleteEntity_v2(DeleteEntity_v2.Input)
  case flagActivityItems(FlagActivityItems.Input)
  case getAdmin
  case getAdminKeychain(GetAdminKeychain.Input)
  case getAdminKeychains
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
  case iosDevice(IOSApp.Device.Id)
  case iosDevices
  case latestAppVersions
  case logEvent(LogEvent.Input)
  case userActivityFeed(UserActivityFeed.Input)
  case childActivitySummaries(ChildActivitySummaries.Input)
  case combinedUsersActivityFeed(CombinedUsersActivityFeed.Input)
  case familyActivitySummaries(FamilyActivitySummaries.Input)
  case getUsers
  case getUserUnlockRequests(GetUserUnlockRequests.Input)
  case saveDevice(SaveDevice.Input)
  case saveKey(SaveKey.Input)
  case saveKeychain(SaveKeychain.Input)
  case saveNotification(SaveNotification.Input)
  case saveUser(SaveUser.Input)
  case toggleChildKeychain(ToggleChildKeychain.Input)
  case stripeUrl
  case securityEventsFeed
  case updateUnlockRequest(UpdateUnlockRequest.Input)
  case requestPublicKeychain(RequestPublicKeychain.Input)
  case upsertBlockRule(UpsertBlockRule.Input)
  case updateIOSDevice(UpdateIOSDevice.Input)
}

extension AuthedParentRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, AuthedParentRoute> =
    OneOf {
      Route(.case(Self.confirmPendingNotificationMethod)) {
        Operation(ConfirmPendingNotificationMethod.self)
        Body(.dashboardInput(ConfirmPendingNotificationMethod.self))
      }
      Route(.case(Self.createPendingAppConnection)) {
        Operation(CreatePendingAppConnection.self)
        Body(.dashboardInput(CreatePendingAppConnection.self))
      }
      Route(.case(Self.createPendingNotificationMethod)) {
        Operation(CreatePendingNotificationMethod.self)
        Body(.dashboardInput(CreatePendingNotificationMethod.self))
      }
      Route(.case(Self.childActivitySummaries)) {
        Operation(ChildActivitySummaries.self)
        Body(.dashboardInput(ChildActivitySummaries.self))
      }
      Route(.case(Self.dashboardWidgets)) {
        Operation(DashboardWidgets.self)
      }
      Route(.case(Self.decideFilterSuspensionRequest)) {
        Operation(DecideFilterSuspensionRequest.self)
        Body(.dashboardInput(DecideFilterSuspensionRequest.self))
      }
      Route(.case(Self.deleteActivityItems_v2)) {
        Operation(DeleteActivityItems_v2.self)
        Body(.dashboardInput(DeleteActivityItems_v2.self))
      }
      Route(.case(Self.deleteEntity_v2)) {
        Operation(DeleteEntity_v2.self)
        Body(.dashboardInput(DeleteEntity_v2.self))
      }
      Route(.case(Self.familyActivitySummaries)) {
        Operation(FamilyActivitySummaries.self)
        Body(.dashboardInput(FamilyActivitySummaries.self))
      }
      Route(.case(Self.flagActivityItems)) {
        Operation(FlagActivityItems.self)
        Body(.dashboardInput(FlagActivityItems.self))
      }
      Route(.case(Self.getAdmin)) {
        Operation(GetAdmin.self)
      }
      Route(.case(Self.getAdminKeychain)) {
        Operation(GetAdminKeychain.self)
        Body(.dashboardInput(GetAdminKeychain.self))
      }
      Route(.case(Self.getAdminKeychains)) {
        Operation(GetAdminKeychains.self)
      }
      Route(.case(Self.getDevice)) {
        Operation(GetDevice.self)
        Body(.dashboardInput(GetDevice.self))
      }
      Route(.case(Self.getDevices)) {
        Operation(GetDevices.self)
      }
      Route(.case(Self.getIdentifiedApps)) {
        Operation(GetIdentifiedApps.self)
      }
      Route(.case(Self.getSelectableKeychains)) {
        Operation(GetSelectableKeychains.self)
      }
      Route(.case(Self.getSuspendFilterRequest)) {
        Operation(GetSuspendFilterRequest.self)
        Body(.dashboardInput(GetSuspendFilterRequest.self))
      }
      Route(.case(Self.getUnlockRequest)) {
        Operation(GetUnlockRequest.self)
        Body(.dashboardInput(GetUnlockRequest.self))
      }
      Route(.case(Self.getUnlockRequests)) {
        Operation(GetUnlockRequests.self)
      }
      Route(.case(Self.getUser)) {
        Operation(GetUser.self)
        Body(.dashboardInput(GetUser.self))
      }
      Route(.case(Self.handleCheckoutCancel)) {
        Operation(HandleCheckoutCancel.self)
        Body(.dashboardInput(HandleCheckoutCancel.self))
      }
      Route(.case(Self.handleCheckoutSuccess)) {
        Operation(HandleCheckoutSuccess.self)
        Body(.dashboardInput(HandleCheckoutSuccess.self))
      }
      Route(.case(Self.iosDevices)) {
        Operation(IOSDevices.self)
      }
      Route(.case(Self.iosDevice)) {
        Operation(GetIOSDevice.self)
        Body(.dashboardInput(GetIOSDevice.self))
      }
      Route(.case(Self.logEvent)) {
        Operation(LogEvent.self)
        Body(.dashboardInput(LogEvent.self))
      }
      Route(.case(Self.userActivityFeed)) {
        Operation(UserActivityFeed.self)
        Body(.dashboardInput(UserActivityFeed.self))
      }
      Route(.case(Self.combinedUsersActivityFeed)) {
        Operation(CombinedUsersActivityFeed.self)
        Body(.dashboardInput(CombinedUsersActivityFeed.self))
      }
      Route(.case(Self.getUsers)) {
        Operation(GetUsers.self)
      }
      Route(.case(Self.getUserUnlockRequests)) {
        Operation(GetUserUnlockRequests.self)
        Body(.dashboardInput(GetUserUnlockRequests.self))
      }
      Route(.case(Self.latestAppVersions)) {
        Operation(LatestAppVersions.self)
      }
      Route(.case(Self.saveDevice)) {
        Operation(SaveDevice.self)
        Body(.dashboardInput(SaveDevice.self))
      }
      Route(.case(Self.saveKey)) {
        Operation(SaveKey.self)
        Body(.dashboardInput(SaveKey.self))
      }
      Route(.case(Self.saveKeychain)) {
        Operation(SaveKeychain.self)
        Body(.dashboardInput(SaveKeychain.self))
      }
      Route(.case(Self.saveNotification)) {
        Operation(SaveNotification.self)
        Body(.dashboardInput(SaveNotification.self))
      }
      Route(.case(Self.saveUser)) {
        Operation(SaveUser.self)
        Body(.dashboardInput(SaveUser.self))
      }
      Route(.case(Self.stripeUrl)) {
        Operation(StripeUrl.self)
      }
      Route(.case(Self.securityEventsFeed)) {
        Operation(SecurityEventsFeed.self)
      }
      Route(.case(Self.toggleChildKeychain)) {
        Operation(ToggleChildKeychain.self)
        Body(.dashboardInput(ToggleChildKeychain.self))
      }
      Route(.case(Self.updateUnlockRequest)) {
        Operation(UpdateUnlockRequest.self)
        Body(.dashboardInput(UpdateUnlockRequest.self))
      }
      Route(.case(Self.requestPublicKeychain)) {
        Operation(RequestPublicKeychain.self)
        Body(.dashboardInput(RequestPublicKeychain.self))
      }
      Route(.case(Self.upsertBlockRule)) {
        Operation(UpsertBlockRule.self)
        Body(.dashboardInput(UpsertBlockRule.self))
      }
      Route(.case(Self.updateIOSDevice)) {
        Operation(UpdateIOSDevice.self)
        Body(.dashboardInput(UpdateIOSDevice.self))
      }
    }
    .eraseToAnyParserPrinter()
}

extension AuthedParentRoute: RouteResponder {
  static func respond(to route: Self, in context: ParentContext) async throws -> Response {
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
    case .childActivitySummaries(let input):
      let output = try await ChildActivitySummaries.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .dashboardWidgets:
      let output = try await DashboardWidgets.resolve(in: context)
      return try await self.respond(with: output)
    case .deleteEntity_v2(let input):
      let output = try await DeleteEntity_v2.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .familyActivitySummaries(let input):
      let output = try await FamilyActivitySummaries.resolve(with: input, in: context)
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
    case .iosDevice(let input):
      let output = try await GetIOSDevice.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .iosDevices:
      let output = try await IOSDevices.resolve(in: context)
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
    case .securityEventsFeed:
      let output = try await SecurityEventsFeed.resolve(in: context)
      return try await self.respond(with: output)
    case .toggleChildKeychain(let input):
      let output = try await ToggleChildKeychain.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .deleteActivityItems_v2(let input):
      let output = try await DeleteActivityItems_v2.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .requestPublicKeychain(let input):
      let output = try await RequestPublicKeychain.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .flagActivityItems(let input):
      let output = try await FlagActivityItems.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .upsertBlockRule(let input):
      let output = try await UpsertBlockRule.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .updateIOSDevice(let input):
      let output = try await UpdateIOSDevice.resolve(with: input, in: context)
      return try await self.respond(with: output)
    }
  }
}

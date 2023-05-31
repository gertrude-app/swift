import Shared
import TypescriptPairQL
import Vapor

enum DashboardTsCodegenRoute {
  struct Response: Content {
    struct Pair: Content {
      let pair: String
      let fetcher: String
    }

    var shared: [String: String]
    var pairs: [String: Pair]
  }

  static func handler(_ request: Request) async throws -> Response {
    Response(
      shared: [
        "\(ClientAuth.self)": ClientAuth.ts,
        "\(DeviceModelFamily.self)": DeviceModelFamily.ts,
        "\(RequestStatus.self)": RequestStatus.ts,
        AdminNotification.Trigger.__typeName: AdminNotification.Trigger.ts,
        Shared.Key.__typeName: Shared.Key.ts,
        "\(AppScope.self)": AppScope.ts,
        AppScope.Single.__typeName: AppScope.Single.ts,
        GetUnlockRequest.Output.__typeName: GetUnlockRequest.Output.ts,
        "\(GetUser.User.self)": GetUser.User.ts,
        "\(KeychainSummary.self)": KeychainSummary.ts,
        "\(GetUser.Device.self)": GetUser.Device.ts,
        GetSuspendFilterRequest.Output.__typeName: GetSuspendFilterRequest.Output.ts,
        Admin.SubscriptionStatus.__typeName: Admin.SubscriptionStatus.ts,
        "\(GetAdminKeychains.AdminKeychain.self)": GetAdminKeychains.AdminKeychain.ts,
        "\(GetAdminKeychains.Key.self)": GetAdminKeychains.Key.ts,
        PqlError.__typeName: PqlError.ts,
      ],
      pairs: [
        AllowingSignups.name: ts(for: AllowingSignups.self),
        ConfirmPendingNotificationMethod.name: ts(for: ConfirmPendingNotificationMethod.self),
        CreateBillingPortalSession.name: ts(for: CreateBillingPortalSession.self),
        CreatePendingAppConnection.name: ts(for: CreatePendingAppConnection.self),
        CreatePendingNotificationMethod.name: ts(for: CreatePendingNotificationMethod.self),
        DeleteActivityItems_v2.name: ts(for: DeleteActivityItems_v2.self),
        DeleteEntity.name: ts(for: DeleteEntity.self),
        GetAdmin.name: ts(for: GetAdmin.self),
        GetAdminKeychain.name: ts(for: GetAdminKeychain.self),
        GetAdminKeychains.name: ts(for: GetAdminKeychains.self),
        GetCheckoutUrl.name: ts(for: GetCheckoutUrl.self),
        GetDashboardWidgets.name: ts(for: GetDashboardWidgets.self),
        GetIdentifiedApps.name: ts(for: GetIdentifiedApps.self),
        GetSelectableKeychains.name: ts(for: GetSelectableKeychains.self),
        GetSuspendFilterRequest.name: ts(for: GetSuspendFilterRequest.self),
        GetUnlockRequest.name: ts(for: GetUnlockRequest.self),
        GetUnlockRequests.name: ts(for: GetUnlockRequests.self),
        GetUser.name: ts(for: GetUser.self),
        UserActivityFeed.name: ts(for: UserActivityFeed.self),
        CombinedUsersActivityFeed.name: ts(for: CombinedUsersActivityFeed.self),
        UserActivitySummaries.name: ts(for: UserActivitySummaries.self),
        CombinedUsersActivitySummaries.name: ts(for: CombinedUsersActivitySummaries.self),
        GetUsers.name: ts(for: GetUsers.self),
        GetUserUnlockRequests.name: ts(for: GetUserUnlockRequests.self),
        HandleCheckoutCancel.name: ts(for: HandleCheckoutCancel.self),
        HandleCheckoutSuccess.name: ts(for: HandleCheckoutSuccess.self),
        JoinWaitlist.name: ts(for: JoinWaitlist.self),
        Login.name: ts(for: Login.self),
        LoginMagicLink.name: ts(for: LoginMagicLink.self),
        RequestMagicLink.name: ts(for: RequestMagicLink.self),
        SaveKey.name: ts(for: SaveKey.self),
        SaveKeychain.name: ts(for: SaveKeychain.self),
        SaveNotification_v0.name: ts(for: SaveNotification_v0.self),
        SaveUser.name: ts(for: SaveUser.self),
        Signup.name: ts(for: Signup.self),
        UpdateSuspendFilterRequest.name: ts(for: UpdateSuspendFilterRequest.self),
        UpdateUnlockRequest.name: ts(for: UpdateUnlockRequest.self),
        VerifySignupEmail.name: ts(for: VerifySignupEmail.self),
      ]
    )
  }

  private static func ts<P: TypescriptPair>(for type: P.Type) -> Response.Pair {
    let name = "\(P.self)"
    var pair = """
    export namespace \(name) {
      \(P.Input.inputTs)

      \(P.Output.outputTs)
    }
    """

    // pairs that are only typealiases get compacted more
    let pairLines = pair.split(separator: "\n")
    if pairLines.count == 4, pairLines.allSatisfy({ $0.count < 60 }) {
      pair = pairLines.joined(separator: "\n")
    }

    var fetchName = "\(name)".regexReplace("_.*$", "")
    let firstLetter = fetchName.removeFirst()
    let functionName = String(firstLetter).lowercased() + fetchName

    let fetcher = """
    \(functionName)(input: T.\(name).Input): Promise<T.Result<T.\(name).Output>> {
      return query<T.\(name).Input, T.\(name).Output>(input, `\(P.auth)`, `\(P.name)`);
    }
    """
    return .init(pair: pair, fetcher: fetcher)
  }
}

// extensions

extension DeviceModelFamily: GlobalType {}
extension AppScope: GlobalType {}
extension RequestStatus: GlobalType {}
extension ClientAuth: GlobalType {}
extension AppScope: TypescriptRepresentable {}
extension PqlError: TypescriptRepresentable {}
extension AppScope.Single: TypescriptRepresentable {}
extension Shared.Key: TypescriptRepresentable {}
extension PqlError.Kind: TypescriptRepresentable {}
extension PqlError.DashboardTag: TypescriptRepresentable {}
extension PqlError.AppTag: TypescriptRepresentable {}

extension PqlError: GlobalType {
  public static var __typeName = "ServerPqlError"
}

extension AppScope.Single: GlobalType {
  public static var __typeName = "SingleAppScope"
}

extension Shared.Key: GlobalType {
  public static var __typeName = "SharedKey"
}

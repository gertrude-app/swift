import Gertie
import PairQL
import Tagged
import TypeScriptInterop
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

  static var sharedTypes: [(String, Any.Type)] {
    [
      ("ServerPqlError", PqlError.self),
      ("ReleaseChannel", ReleaseChannel.self),
      ("SingleAppScope", AppScope.Single.self),
      ("AppScope", AppScope.self),
      ("SharedKey", Gertie.Key.self),
      ("Key", GetAdminKeychains.Key.self),
      ("SuccessOutput", SuccessOutput.self),
      ("ClientAuth", ClientAuth.self),
      ("DeviceModelFamily", DeviceModelFamily.self),
      ("RequestStatus", RequestStatus.self),
      ("UnlockRequest", GetUnlockRequest.Output.self),
      ("KeychainSummary", KeychainSummary.self),
      ("UserDevice", GetUser.Device.self),
      ("Device", GetDevice.Output.self),
      ("User", GetUser.User.self),
      ("SuspendFilterRequest", GetSuspendFilterRequest.Output.self),
      ("AdminKeychain", GetAdminKeychains.AdminKeychain.self),
      ("UserActivityItem", UserActivity.Item.self),
      ("AdminNotificationTrigger", AdminNotification.Trigger.self),
      ("AdminSubscriptionStatus", GetAdmin.SubscriptionStatus.self),
      ("VerifiedNotificationMethod", GetAdmin.VerifiedNotificationMethod.self),
      ("AdminNotification", GetAdmin.Notification.self),
    ]
  }

  static var pairqlPairs: [any Pair.Type] {
    [
      UserActivityFeed.self,
      GetAdmin.self,
      ConfirmPendingNotificationMethod.self,
      CreatePendingAppConnection.self,
      CreatePendingNotificationMethod.self,
      DeleteActivityItems_v2.self,
      DeleteEntity.self,
      GetAdmin.self,
      GetAdminKeychain.self,
      GetAdminKeychains.self,
      GetDevice.self,
      GetDevices.self,
      GetDashboardWidgets.self,
      GetIdentifiedApps.self,
      GetSelectableKeychains.self,
      GetSuspendFilterRequest.self,
      GetUnlockRequest.self,
      GetUnlockRequests.self,
      GetUser.self,
      HandleCheckoutCancel.self,
      HandleCheckoutSuccess.self,
      LatestAppVersions.self,
      UserActivityFeed.self,
      CombinedUsersActivityFeed.self,
      UserActivitySummaries.self,
      CombinedUsersActivitySummaries.self,
      GetUsers.self,
      GetUserUnlockRequests.self,
      Login.self,
      LoginMagicLink.self,
      RequestMagicLink.self,
      ResetPassword.self,
      SaveDevice.self,
      SaveKey.self,
      SaveKeychain.self,
      SaveNotification.self,
      SaveUser.self,
      SendPasswordResetEmail.self,
      Signup.self,
      StripeUrl.self,
      DecideFilterSuspensionRequest.self,
      UpdateUnlockRequest.self,
      VerifySignupEmail.self,
      HollandTalkSubscription.self,
    ]
  }

  static func handler(_ request: Request) async throws -> Response {
    var shared: [String: String] = [:]
    var sharedAliases: [Config.Alias] = [
      .init(NoInput.self, as: "void"),
      .init(Date.self, as: "ISODateString"),
    ]
    var config = Config(compact: true, aliasing: sharedAliases)

    for (name, type) in sharedTypes {
      shared[name] = try CodeGen(config: config).declaration(for: type, as: name)
      sharedAliases.append(.init(type, as: name))
      config = .init(compact: true, aliasing: sharedAliases)
    }

    var pairs: [String: Response.Pair] = [:]
    for pairType in pairqlPairs {
      pairs[pairType.name] = try ts(for: pairType, with: config)
    }

    return Response(shared: shared, pairs: pairs)
  }

  private static func ts<P: Pair>(
    for type: P.Type,
    with config: Config
  ) throws -> Response.Pair {
    let codegen = CodeGen(config: config)
    let name = "\(P.self)"
    var pair = """
    export namespace \(name) {
      \(try codegen.declaration(for: P.Input.self, as: "Input"))

      \(try codegen.declaration(for: P.Output.self, as: "Output"))
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

extension Tagged: TypeScriptAliased where RawValue == UUID {
  public static var typescriptAlias: String {
    "UUID"
  }
}

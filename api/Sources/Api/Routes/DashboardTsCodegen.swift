import Shared
import TypescriptPairQL
import Vapor

enum DashboardTsCodegenRoute {
  struct Response: Content {
    var shared: String
    var types: [String: String]
  }

  static func handler(_ request: Request) async throws -> Response {
    Response(
      shared: [
        ClientAuth.ts,
        DeviceModelFamily.ts,
      ].joined(separator: "\n\n"),
      types: [
        AllowingSignups.name: ts(for: AllowingSignups.self),
        ConfirmPendingNotificationMethod.name: ts(for: ConfirmPendingNotificationMethod.self),
        CreateBillingPortalSession.name: ts(for: CreateBillingPortalSession.self),
        CreatePendingAppConnection.name: ts(for: CreatePendingAppConnection.self),
        CreatePendingNotificationMethod.name: ts(for: CreatePendingNotificationMethod.self),
        DeleteActivityItems.name: ts(for: DeleteActivityItems.self),
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
        GetUserActivityDay.name: ts(for: GetUserActivityDay.self),
        GetUserActivityDays.name: ts(for: GetUserActivityDays.self),
        GetUsers.name: ts(for: GetUsers.self),
        GetUserUnlockRequests.name: ts(for: GetUserUnlockRequests.self),
        HandleCheckoutCancel.name: ts(for: HandleCheckoutCancel.self),
        HandleCheckoutSuccess.name: ts(for: HandleCheckoutSuccess.self),
        JoinWaitlist.name: ts(for: JoinWaitlist.self),
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
}

private func ts<P: TypescriptPair>(for type: P.Type) -> String {
  """
  export namespace \(P.self) {
    \(P.Input.ts.replacingOccurrences(of: "__self__", with: "Input"))

    \(P.Output.ts.replacingOccurrences(of: "__self__", with: "Output"))

    export async function fetch(input: Input): Promise<PqlResult<Output>> {
      return pqlQuery<Input, Output>(input, ClientAuth.\(P.auth), `\(P.name)`)
    }
  }
  """
}

extension DeviceModelFamily: SharedType {}

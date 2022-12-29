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
        CreateBillingPortalSession.name: ts(for: CreateBillingPortalSession.self),
        CreatePendingAppConnection.name: ts(for: CreatePendingAppConnection.self),
        DeleteUser.name: ts(for: DeleteUser.self),
        GetAdmin.name: ts(for: GetAdmin.self),
        GetCheckoutUrl.name: ts(for: GetCheckoutUrl.self),
        GetUser.name: ts(for: GetUser.self),
        GetUserActivityDay.name: ts(for: GetUserActivityDay.self),
        GetUserActivityDays.name: ts(for: GetUserActivityDays.self),
        GetUsers.name: ts(for: GetUsers.self),
        HandleCheckoutCancel.name: ts(for: HandleCheckoutCancel.self),
        HandleCheckoutSuccess.name: ts(for: HandleCheckoutSuccess.self),
        JoinWaitlist.name: ts(for: JoinWaitlist.self),
        LoginMagicLink.name: ts(for: LoginMagicLink.self),
        RequestMagicLink.name: ts(for: RequestMagicLink.self),
        SaveUser.name: ts(for: SaveUser.self),
        Signup.name: ts(for: Signup.self),
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

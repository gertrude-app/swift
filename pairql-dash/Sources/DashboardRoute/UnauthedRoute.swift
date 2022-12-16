import Foundation
import TypescriptPairQL

public enum UnauthedRoute: PairRoute {
  case tsCodegen
  case signup(Signup.Input)
  case verifySignupEmail(VerifySignupEmail.Input)
  case joinWaitlist(JoinWaitlist.Input)
  case allowingSignups
  case getCheckoutUrl(GetCheckoutUrl.Input)
  case handleCheckoutSuccess(HandleCheckoutSuccess.Input)

  public static let router = OneOf {
    Route(/Self.tsCodegen) {
      Operation(TsCodegen.self)
    }
    Route(/Self.signup) {
      Operation(Signup.self)
      Body(.json(Signup.Input.self))
    }
    Route(/Self.verifySignupEmail) {
      Operation(VerifySignupEmail.self)
      Body(.json(VerifySignupEmail.Input.self))
    }
    Route(/Self.joinWaitlist) {
      Operation(JoinWaitlist.self)
      Body(.json(JoinWaitlist.Input.self))
    }
    Route(/Self.allowingSignups) {
      Operation(AllowingSignups.self)
    }
    Route(/Self.getCheckoutUrl) {
      Operation(GetCheckoutUrl.self)
      Body(.json(GetCheckoutUrl.Input.self))
    }
    Route(/Self.handleCheckoutSuccess) {
      Operation(HandleCheckoutSuccess.self)
      Body(.json(HandleCheckoutSuccess.Input.self))
    }
  }
}

public struct TsCodegen: Pair, TypescriptPair {
  public static var auth: ClientAuth = .none
  public typealias Output = [String: String]
}

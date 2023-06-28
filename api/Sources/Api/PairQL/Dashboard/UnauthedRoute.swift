import Foundation
import PairQL
import Vapor

enum UnauthedRoute: PairRoute {
  case allowingSignups
  case getCheckoutUrl(GetCheckoutUrl.Input)
  case handleCheckoutCancel(HandleCheckoutCancel.Input)
  case handleCheckoutSuccess(HandleCheckoutSuccess.Input)
  case joinWaitlist(JoinWaitlist.Input)
  case login(Login.Input)
  case loginMagicLink(LoginMagicLink.Input)
  case requestMagicLink(RequestMagicLink.Input)
  case signup(Signup.Input)
  case verifySignupEmail(VerifySignupEmail.Input)

  static let router = OneOf {
    Route(/Self.allowingSignups) {
      Operation(AllowingSignups.self)
    }
    Route(/Self.getCheckoutUrl) {
      Operation(GetCheckoutUrl.self)
      Body(.dashboardInput(GetCheckoutUrl.self))
    }
    Route(/Self.handleCheckoutCancel) {
      Operation(HandleCheckoutCancel.self)
      Body(.dashboardInput(HandleCheckoutCancel.self))
    }
    Route(/Self.handleCheckoutSuccess) {
      Operation(HandleCheckoutSuccess.self)
      Body(.dashboardInput(HandleCheckoutSuccess.self))
    }
    Route(/Self.joinWaitlist) {
      Operation(JoinWaitlist.self)
      Body(.dashboardInput(JoinWaitlist.self))
    }
    Route(/Self.login) {
      Operation(Login.self)
      Body(.dashboardInput(Login.self))
    }
    Route(/Self.loginMagicLink) {
      Operation(LoginMagicLink.self)
      Body(.dashboardInput(LoginMagicLink.self))
    }
    Route(/Self.requestMagicLink) {
      Operation(RequestMagicLink.self)
      Body(.dashboardInput(RequestMagicLink.self))
    }
    Route(/Self.signup) {
      Operation(Signup.self)
      Body(.dashboardInput(Signup.self))
    }
    Route(/Self.verifySignupEmail) {
      Operation(VerifySignupEmail.self)
      Body(.dashboardInput(VerifySignupEmail.self))
    }
  }
}

extension UnauthedRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {
    case .signup(let input):
      let output = try await Signup.resolve(with: input, in: context)
      return try await respond(with: output)
    case .verifySignupEmail(let input):
      let output = try await VerifySignupEmail.resolve(with: input, in: context)
      return try await respond(with: output)
    case .joinWaitlist(let input):
      let output = try await JoinWaitlist.resolve(with: input, in: context)
      return try await respond(with: output)
    case .allowingSignups:
      let output = try await AllowingSignups.resolve(in: context)
      return try await respond(with: output)
    case .getCheckoutUrl(let input):
      let output = try await GetCheckoutUrl.resolve(with: input, in: context)
      return try await respond(with: output)
    case .handleCheckoutSuccess(let input):
      let output = try await HandleCheckoutSuccess.resolve(with: input, in: context)
      return try await respond(with: output)
    case .handleCheckoutCancel(let input):
      let output = try await HandleCheckoutCancel.resolve(with: input, in: context)
      return try await respond(with: output)
    case .login(let input):
      let output = try await Login.resolve(with: input, in: context)
      return try await respond(with: output)
    case .loginMagicLink(let input):
      let output = try await LoginMagicLink.resolve(with: input, in: context)
      return try await respond(with: output)
    case .requestMagicLink(let input):
      let output = try await RequestMagicLink.resolve(with: input, in: context)
      return try await respond(with: output)
    }
  }
}

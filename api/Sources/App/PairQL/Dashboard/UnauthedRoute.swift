import Foundation
import TypescriptPairQL
import Vapor

enum UnauthedRoute: PairRoute {
  case signup(Signup.Input)
  case verifySignupEmail(VerifySignupEmail.Input)
  case joinWaitlist(JoinWaitlist.Input)
  case allowingSignups
  case getCheckoutUrl(GetCheckoutUrl.Input)
  case handleCheckoutSuccess(HandleCheckoutSuccess.Input)
  case handleCheckoutCancel(HandleCheckoutCancel.Input)
  case requestMagicLink(RequestMagicLink.Input)
  case loginMagicLink(LoginMagicLink.Input)

  static let router = OneOf {
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
    Route(/Self.handleCheckoutCancel) {
      Operation(HandleCheckoutCancel.self)
      Body(.json(HandleCheckoutCancel.Input.self))
    }
    Route(/Self.requestMagicLink) {
      Operation(RequestMagicLink.self)
      Body(.json(RequestMagicLink.Input.self))
    }
    Route(/Self.loginMagicLink) {
      Operation(LoginMagicLink.self)
      Body(.json(LoginMagicLink.Input.self))
    }
  }
}

extension UnauthedRoute: RouteResponder {
  static func respond(to route: Self, in context: DashboardContext) async throws -> Response {
    switch route {
    case .signup(let input):
      let output = try await Signup.resolve(for: input, in: context)
      return try await respond(with: output)
    case .verifySignupEmail(let input):
      let output = try await VerifySignupEmail.resolve(for: input, in: context)
      return try await respond(with: output)
    case .joinWaitlist(let input):
      let output = try await JoinWaitlist.resolve(for: input, in: context)
      return try await respond(with: output)
    case .allowingSignups:
      let output = try await AllowingSignups.resolve(in: context)
      return try await respond(with: output)
    case .getCheckoutUrl(let input):
      let output = try await GetCheckoutUrl.resolve(for: input, in: context)
      return try await respond(with: output)
    case .handleCheckoutSuccess(let input):
      let output = try await HandleCheckoutSuccess.resolve(for: input, in: context)
      return try await respond(with: output)
    case .handleCheckoutCancel(let input):
      let output = try await HandleCheckoutCancel.resolve(for: input, in: context)
      return try await respond(with: output)
    case .loginMagicLink(let input):
      let output = try await LoginMagicLink.resolve(for: input, in: context)
      return try await respond(with: output)
    case .requestMagicLink(let input):
      let output = try await RequestMagicLink.resolve(for: input, in: context)
      return try await respond(with: output)
    }
  }
}

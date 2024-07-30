import Foundation
import PairQL
import Vapor

enum UnauthedRoute: PairRoute {
  case login(Login.Input)
  case loginMagicLink(LoginMagicLink.Input)
  case requestMagicLink(RequestMagicLink.Input)
  case resetPassword(ResetPassword.Input)
  case saveConferenceEmail(SaveConferenceEmail.Input)
  case sendPasswordResetEmail(SendPasswordResetEmail.Input)
  case signup(Signup.Input)
  case verifySignupEmail(VerifySignupEmail.Input)

  nonisolated(unsafe) static let router = OneOf {
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
    Route(/Self.resetPassword) {
      Operation(ResetPassword.self)
      Body(.dashboardInput(ResetPassword.self))
    }
    Route(/Self.saveConferenceEmail) {
      Operation(SaveConferenceEmail.self)
      Body(.dashboardInput(SaveConferenceEmail.self))
    }
    Route(/Self.sendPasswordResetEmail) {
      Operation(SendPasswordResetEmail.self)
      Body(.dashboardInput(SendPasswordResetEmail.self))
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
      return try await self.respond(with: output)
    case .verifySignupEmail(let input):
      let output = try await VerifySignupEmail.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .login(let input):
      let output = try await Login.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .loginMagicLink(let input):
      let output = try await LoginMagicLink.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .requestMagicLink(let input):
      let output = try await RequestMagicLink.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .resetPassword(let input):
      let output = try await ResetPassword.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .saveConferenceEmail(let input):
      let output = try await SaveConferenceEmail.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .sendPasswordResetEmail(let input):
      let output = try await SendPasswordResetEmail.resolve(with: input, in: context)
      return try await self.respond(with: output)
    }
  }
}

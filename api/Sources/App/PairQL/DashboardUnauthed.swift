import DashboardRoute
import DuetSQL
import Vapor

extension UnauthedRoute: RouteResponder {
  static func respond(to route: Self, in context: DashboardContext) async throws -> Response {
    switch route {
    case .tsCodegen:
      fatalError("Unimplemented")
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
    }
  }
}

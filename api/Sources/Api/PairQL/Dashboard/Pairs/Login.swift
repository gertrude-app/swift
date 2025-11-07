import DuetSQL
import Gertie
import PairQL
import Vapor
import XCore

struct Login: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    let email: String
    let password: String
  }

  struct Output: PairOutput {
    let adminId: Parent.Id
    let token: Parent.DashToken.Value
  }
}

// resolver

extension Login: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let parent = try await Parent.query()
      .where(.email == .string(input.email.lowercased()))
      .first(in: context.db, orThrow: context |> loginError)

    if parent.subscriptionStatus == .pendingEmailVerification {
      try await sendVerificationEmail(to: parent, in: context)
      throw context.error(
        "4b5bbea0",
        .unauthorized,
        user: "You may not login until your email is verified. Please check your email for a new verification link.",
      )
    }

    let match: Bool = switch context.env.mode {
    case .test:
      // for test speed, bcrypt verification is slow, by design
      input.password == parent.password
    case .dev:
      if input.password == "good" {
        true
      } else {
        try Bcrypt.verify(input.password, created: parent.password)
      }
    case .prod, .staging:
      try Bcrypt.verify(input.password, created: parent.password)
    }

    if match {
      dashSecurityEvent(.login, "using email/password", parent: parent.id, in: context)
    } else {
      dashSecurityEvent(.loginFailed, "incorrect password", parent: parent.id, in: context)
      throw context |> loginError
    }

    let token = try await context.db.create(Parent.DashToken(parentId: parent.id))
    return .init(adminId: parent.id, token: token.value)
  }
}

extension Login {
  static func loginError(_ context: Context) -> PqlError {
    context.error("1e087878", .unauthorized, user: "Incorrect email or password")
  }
}

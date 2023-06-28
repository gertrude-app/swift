import DuetSQL
import PairQL
import Vapor
import XCore

struct Login: Pair {
  static var auth: ClientAuth = .none

  struct Input: PairInput {
    let email: String
    let password: String
  }

  struct Output: PairOutput {
    let adminId: Admin.Id
    let token: AdminToken.Value
  }
}

// resolver

extension Login: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let admin = try await Current.db.query(Admin.self)
      .where(.email == .string(input.email.lowercased()))
      .first(orThrow: context |> error)

    let match: Bool
    switch Env.mode {
    case .test:
      // for test speed, bcrypt verification is slow, by design
      match = input.password == admin.password
    case .dev:
      if input.password == "good" {
        match = true
      } else {
        match = try Bcrypt.verify(input.password, created: admin.password)
      }
    case .prod, .staging:
      match = try Bcrypt.verify(input.password, created: admin.password)
    }

    if !match { throw context |> error }

    let token = try await Current.db.create(AdminToken(adminId: admin.id))
    return .init(adminId: admin.id, token: token.value)
  }
}

extension Login {
  static func error(_ context: Context) -> PqlError {
    context.error("1e087878", .unauthorized, user: "Incorrect email or password")
  }
}

import DuetSQL
import TypescriptPairQL
import Vapor

struct Login: TypescriptPair {
  static var auth: ClientAuth = .none

  struct Input: TypescriptPairInput {
    let email: String
    let password: String
  }

  struct Output: TypescriptPairOutput {
    let adminId: Admin.Id
    let token: AdminToken.Value
  }
}

// resolver

extension Login: Resolver {
  static func resolve(
    with input: Input,
    in context: DashboardContext
  ) async throws -> Output {
    let admin = try await Current.db.query(Admin.self)
      .where(.email == .string(input.email.lowercased()))
      .first()

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

    if !match {
      throw Abort(.unauthorized)
    }
    let token = try await Current.db.create(AdminToken(adminId: admin.id))
    return .init(adminId: admin.id, token: token.value)
  }
}

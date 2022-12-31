import DuetSQL
import TypescriptPairQL
import Vapor

struct JoinWaitlist: TypescriptPair {
  static var auth: ClientAuth = .none

  struct Input: TypescriptPairInput {
    var email: String
  }
}

// resolver

extension JoinWaitlist: Resolver {
  static func resolve(
    with input: Input,
    in context: DashboardContext
  ) async throws -> Output {
    let email = input.email.lowercased()
    guard email.isValidEmail else {
      throw Abort(.badRequest)
    }

    let waitlisted = WaitlistedAdmin(email: .init(email))
    let existing = try? await Current.db.query(WaitlistedAdmin.self)
      .where(.email == .string(waitlisted.email.rawValue))
      .first()
    if existing != nil { return .success }

    if Env.mode == .prod {
      Current.sendGrid.fireAndForget(.toJared("Gertrude waitlist", "email: \(email)"))
    }

    try await Current.db.create(waitlisted)
    return .success
  }
}

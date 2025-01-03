import DuetSQL
import Foundation
import PairQL
import Vapor

struct SendPasswordResetEmail: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    var email: String
  }
}

// resolver

extension SendPasswordResetEmail: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let postmark = get(dependency: \.postmark)
    let email = input.email.lowercased()
    if !email.isValidEmail {
      throw Abort(.badRequest)
    }
    if let admin = try? await Admin.query()
      .where(.email == email)
      .first(in: context.db) {
      let token = await with(dependency: \.ephemeral)
        .createAdminIdToken(admin.id)
      dashSecurityEvent(.passwordResetRequested, admin: admin.id, in: context)
      try await postmark.send(template: .passwordReset(
        to: email,
        model: .init(dashboardUrl: context.dashboardUrl, token: token)
      ))
    } else {
      try await postmark.send(template: .passwordResetNoAccount(to: email, model: .init()))
    }
    return .success
  }
}

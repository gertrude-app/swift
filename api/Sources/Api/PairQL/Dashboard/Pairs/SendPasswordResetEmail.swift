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
    guard email.isValidEmail else {
      throw Abort(.badRequest)
    }

    if let parent = try? await Parent.query()
      .where(.email == email)
      .first(in: context.db) {
      let token = await with(dependency: \.ephemeral)
        .createParentIdToken(parent.id)
      dashSecurityEvent(.passwordResetRequested, parent: parent.id, in: context)
      try await postmark.send(template: .passwordReset(
        to: email,
        model: .init(dashboardUrl: context.dashboardUrl, token: token),
      ))
    } else {
      try await postmark.send(template: .passwordResetNoAccount(to: email, model: .init()))
    }
    return .success
  }
}

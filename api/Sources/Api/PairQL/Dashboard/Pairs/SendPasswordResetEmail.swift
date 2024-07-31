import DuetSQL
import Foundation
import PairQL
import Vapor
import XPostmark

struct SendPasswordResetEmail: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    var email: String
  }
}

// resolver

extension SendPasswordResetEmail: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let email = input.email.lowercased()
    if !email.isValidEmail {
      throw Abort(.badRequest)
    }
    if let admin = try? await Admin.query().where(.email == email).first() {
      let token = await Current.ephemeral.createAdminIdToken(admin.id)
      dashSecurityEvent(.passwordResetRequested, admin.id, context.ipAddress)
      try await Current.postmark.send(reset(email, context.dashboardUrl, token))
    } else {
      try await Current.postmark.send(notFound(email))
    }
    return .success
  }
}

// emails

private func reset(_ email: String, _ dashboardUrl: String, _ token: UUID) -> XPostmark.Email {
  .init(
    to: email,
    from: "Gertrude App <noreply@gertrude.app>",
    subject: "Gertrude password reset".withEmailSubjectDisambiguator,
    html: """
    You can reset your Gertrude account password by clicking \
    <a href="\(dashboardUrl)/reset-password/\(token.lowercased)">here</a>.
    """
  )
}

private func notFound(_ email: String) -> XPostmark.Email {
  .init(
    to: email,
    from: "Gertrude App <noreply@gertrude.app>",
    subject: "Gertrude app password reset".withEmailSubjectDisambiguator,
    html: """
    A password reset was requested for this email address, \
    but no Gertrude account exists with this email address. \
    Perhaps you signed up with a different email address? <br /><br /> \
    Or, if you did not request a reset, you can safely ignore this email.
    """
  )
}

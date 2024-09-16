import DuetSQL
import PairQL
import Vapor

struct RequestMagicLink: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    var email: String
    var redirect: String?
  }
}

// resolver

extension RequestMagicLink: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let email = input.email.lowercased()
    guard email.isValidEmail else {
      throw Abort(.badRequest)
    }

    let admin = try? await Admin.query()
      .where(.email == .string(email))
      .first(in: context.db)

    guard let admin else {
      let noAccountEmail = Email.fromApp(
        to: email,
        subject: "Gertrude App Magic Link",
        html: """
        A magic login link was requested for this email address, \
        but no Gertrude account exists with this email address. \
        Perhaps you signed up with a different email address? <br /><br /> \
        Or, if you did not request a magic link, you can safely ignore this email.
        """
      )
      try await with(dependency: \.sendgrid).send(noAccountEmail)
      return .success
    }

    let token = await with(dependency: \.ephemeral)
      .createAdminIdToken(admin.id)
    let subject = "Gertrude App Magic Link"
    var url = "\(context.dashboardUrl)/otp/\(token.lowercased)"
    if let redirect = input.redirect,
       let encoded = redirect.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
      url += "?redirect=\(encoded)"
    }
    let html = "<a href='\(url)'>Click here</a> to log in to the Gertrude dashboard."
    let magicLinkEmail = Email.fromApp(to: admin.email.rawValue, subject: subject, html: html)
    try await with(dependency: \.sendgrid).send(magicLinkEmail)

    return .success
  }
}

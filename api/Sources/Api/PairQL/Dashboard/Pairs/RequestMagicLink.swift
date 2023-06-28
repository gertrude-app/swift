import DuetSQL
import PairQL

struct RequestMagicLink: Pair {
  static var auth: ClientAuth = .none

  struct Input: PairInput {
    var email: String
    var redirect: String?
  }
}

// resolver

extension RequestMagicLink: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let admin = try? await Current.db.query(Admin.self)
      .where(.email == .string(input.email.lowercased()))
      .first()

    guard let admin = admin else {
      Current.logger.error("Failed attempt to retrieve magic link for email: `\(input.email)`")
      #if !DEBUG
        try? await Task.sleep(seconds: 2)
      #endif
      return .success
    }

    let token = await Current.ephemeral.createMagicLinkToken(admin.id)
    let subject = "Gertrude Dashboard Magic Link"
    var url = "\(context.dashboardUrl)/otp/\(token.lowercased)"
    if let redirect = input.redirect,
       let encoded = redirect.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
      url += "?redirect=\(encoded)"
    }
    let html = "<a href='\(url)'>Click here</a> to log in to the Gertrude dashboard."
    let email = Email.fromApp(to: admin.email.rawValue, subject: subject, html: html)
    try await Current.sendGrid.send(email)

    return .success
  }
}

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
    let postmark = get(dependency: \.postmark)
    let email = input.email.lowercased()
    guard email.isValidEmail else {
      throw Abort(.badRequest)
    }

    let admin = try? await Admin.query()
      .where(.email == .string(email))
      .first(in: context.db)

    guard let admin else {
      try await postmark.send(template: .magicLinkNoAccount(to: email, model: .init()))
      return .success
    }

    let token = await with(dependency: \.ephemeral)
      .createAdminIdToken(admin.id)
    var url = "\(context.dashboardUrl)/otp/\(token.lowercased)"
    if let redirect = input.redirect,
       let encoded = redirect.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
      url += "?redirect=\(encoded)"
    }
    try await postmark.send(template: .magicLink(to: email, model: .init(url: url)))
    return .success
  }
}

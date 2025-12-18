import DuetSQL
import PairQL
import Vapor

struct RequestAdminMagicLink: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    var email: String
  }

  struct Output: PairOutput {
    var success: Bool
  }
}

extension RequestAdminMagicLink: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let email = input.email.lowercased().trimmingCharacters(in: .whitespaces)

    guard email.isValidEmail else {
      throw context.error("f8f93d61", .badRequest, "Invalid email address")
    }

    let allowedEmails = context.env.get("ADMIN_SITE_AUTH_EMAILS")?
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespaces).lowercased() } ?? []

    guard allowedEmails.contains(email) else {
      get(dependency: \.logger).info("Rejected admin magic link request for \(email)")
      return .init(success: true)
    }

    let postmark = get(dependency: \.postmark)
    let token = await with(dependency: \.ephemeral).createSuperAdminToken(email)
    let adminUrl = context.env.get("ADMIN_URL") ?? "http://localhost:4243"
    let url = "\(adminUrl)/verify/\(token.uuidString.lowercased())"
    get(dependency: \.logger).info("Admin magic link requested for `\(email)`")

    try await postmark.send(
      to: email,
      subject: "Gertrude Admin Login",
      html: """
      <p>Click the link below to log in to the Gertrude admin dashboard:</p>
      <p><a href="\(url)">\(url)</a></p>
      <p>This link expires in 1 hour.</p>
      """,
    )
    return .init(success: true)
  }
}

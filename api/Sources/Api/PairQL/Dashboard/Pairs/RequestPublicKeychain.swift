import Dependencies
import PairQL

struct RequestPublicKeychain: Pair {
  static let auth: ClientAuth = .admin

  struct Input: PairInput {
    var searchQuery: String
    var description: String
  }
}

extension RequestPublicKeychain: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> PairQL
    .SuccessOutput {
    @Dependency(\.postmark) var postmark
    @Dependency(\.logger) var logger

    let html = """
    <p>From admin <b>\(
      context.admin.email
        .raw
    )</b> (<a href="https://gertrude-analytics.vercel.app/admins/\(
      context.admin
        .id
    )">view in analytics site</a>).</p>
    <p>They searched for "<b>\(input.searchQuery)</b>". This is what they want:</p>
    <code>"\(input.description)"</code>
    """

    do {
      try await postmark.send(.init(
        to: processEnv("PRIMARY_SUPPORT_EMAIL"),
        from: context.admin.email.raw,
        replyTo: context.admin.email.raw,
        subject: "Public keychain request",
        html: html
      ))
      return .success
    } catch {
      logger.error("""
      Failed to send public keychain request email
      From: \(context.admin.email.raw)
      Query: \(input.searchQuery)
      Description: \(input.description)
      Error: \(error)
      """)
      return .failure
    }
  }
}

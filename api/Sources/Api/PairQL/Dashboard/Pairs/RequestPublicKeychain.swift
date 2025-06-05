import Dependencies
import PairQL

struct RequestPublicKeychain: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var searchQuery: String
    var description: String
  }
}

extension RequestPublicKeychain: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    @Dependency(\.postmark) var postmark

    let html = """
    <p>From admin <b>\(
      context.parent.email
    )</b> (<a href="https://gertrude-analytics.vercel.app/admins/\(
      context.parent
        .id
    )">view in analytics site</a>).</p>
    <p>They searched for "<b>\(input.searchQuery)</b>". This is what they want:</p>
    <code>"\(input.description)"</code>
    """

    postmark.toSuperAdmin("Public keychain request", html)
    return .success
  }
}

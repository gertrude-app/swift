import DuetSQL
import Gertie
import PairQL

struct CreateDashAnnouncement: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Input: PairInput {
    let icon: String? // default: `fa fa-bolt` in web
    let html: String
    let learnMoreUrl: String?
  }
}

// resolver

extension CreateDashAnnouncement: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let parents = try await Admin.query()
      .where(.createdAt < Date() - .days(2))
      .all(in: context.db)

    try await context.db.create(parents.map {
      DashAnnouncement(
        parentId: $0.id,
        icon: input.icon,
        html: input.html,
        learnMoreUrl: input.learnMoreUrl
      )
    })

    return .success
  }
}

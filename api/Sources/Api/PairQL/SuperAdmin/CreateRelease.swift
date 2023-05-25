import DuetSQL
import PairQL
import Gertie

struct CreateRelease: Pair {
  static var auth: ClientAuth = .superAdmin

  struct Input: PairInput {
    let semver: String
    let channel: ReleaseChannel
    let signature: String
    let length: Int
    let appRevision: String
    let coreRevision: String
  }

  struct Output: PairOutput {
    let id: Release.Id
  }
}

// resolver

extension CreateRelease: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    // allow overwriting existing release, identified by semver string
    let existing = try? await Current.db.query(Release.self)
      .where(.semver == .string(input.semver))
      .first()

    if let existing = existing {
      existing.channel = input.channel
      existing.signature = input.signature
      existing.length = input.length
      existing.appRevision = .init(rawValue: input.appRevision)
      existing.coreRevision = .init(rawValue: input.coreRevision)
      try await Current.db.update(existing)
      return .init(id: existing.id)
    }

    let release = try await Current.db.create(Release(
      semver: input.semver,
      channel: input.channel,
      signature: input.signature,
      length: input.length,
      appRevision: .init(input.appRevision),
      coreRevision: .init(input.coreRevision)
    ))

    return .init(id: release.id)
  }
}

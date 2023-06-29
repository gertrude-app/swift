import DuetSQL
import MacAppRoute

extension LatestAppVersion: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let release = try await Current.db.query(Release.self)
      .where(.channel == input)
      .orderBy(.createdAt, .desc)
      .limit(1)
      .first()
    return release.semver
  }
}

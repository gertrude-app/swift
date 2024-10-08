import MacAppRoute

extension RecentAppVersions: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    let versions = try await Release.query()
      .orderBy(.createdAt, .desc)
      .limit(12)
      .all(in: context.db)
    return versions.reduce(into: [:]) { dict, release in
      let channel = release.channel == .stable ? "" : " (\(release.channel))"
      dict[release.semver] = "\(release.semver)\(channel)"
    }
  }
}

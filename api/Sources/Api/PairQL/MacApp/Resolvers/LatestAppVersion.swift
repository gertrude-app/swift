import DuetSQL
import Gertie
import MacAppRoute

extension LatestAppVersion: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let releases = try await Release.query()
      .orderBy(.semver, .asc)
      .all(in: context.db)

    let currentSemver = Semver(input.currentVersion)!
    var output = Output(semver: currentSemver.string)

    for release in releases {
      if currentSemver.isBehind(release),
         release.channel.isAtLeastAsStable(as: input.releaseChannel) {
        output.semver = release.semver
        if let pace = release.requirementPace, output.pace == nil {
          output.pace = .init(
            nagOn: release.createdAt.advanced(by: .days(pace)),
            requireOn: release.createdAt.advanced(by: .days(pace * 2))
          )
        }
      }
    }

    return output
  }
}

import DuetSQL
import Gertie
import MacAppRoute

extension LatestAppVersion: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let releases = try await Current.db.query(Release.self)
      .where(.channel == input.releaseChannel)
      .orderBy(.semver, .asc)
      .all()

    let current = Semver(input.currentVersion)!
    var output = Output(semver: releases.first?.semver ?? "0.0.0")

    for release in releases {
      output.semver = release.semver
      if current < Semver(release.semver)!,
         let pace = release.requirementPace,
         output.pace == nil {
        output.pace = .init(
          nagOn: release.createdAt.advanced(by: .days(pace)),
          requireOn: release.createdAt.advanced(by: .days(pace * 2))
        )
      }
    }

    return output
  }
}

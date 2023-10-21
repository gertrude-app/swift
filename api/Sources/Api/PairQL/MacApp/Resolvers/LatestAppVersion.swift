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

    // if they're on a beta/canary version ahead of their app release channel
    // don't tell them there's an update to an older version
    // this allows me to release "beta" versions to new customers without
    // bothering existing users with an update
    if current > Semver(output.semver)! {
      output.semver = current.string
    }

    for release in releases {
      if current < Semver(release.semver)! {
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

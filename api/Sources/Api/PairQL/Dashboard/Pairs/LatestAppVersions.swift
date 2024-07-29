import Foundation
import Gertie
import PairQL

struct LatestAppVersions: Pair {
  static let auth: ClientAuth = .admin

  struct Output: PairOutput {
    var stable: String
    var beta: String
    var canary: String
  }
}

// resolver

extension LatestAppVersions: NoInputResolver {
  static func resolve(in context: AdminContext) async throws -> Output {
    let releases = try await Release.query()
      .orderBy(.semver, .asc)
      .all()

    var latest = Output(
      stable: "0.0.0",
      beta: "0.0.0",
      canary: "0.0.0"
    )

    for release in releases {
      switch release.channel {
      case .stable:
        if Semver(release) > Semver(latest.stable)! {
          latest.stable = release.semver
        }
      case .beta:
        if Semver(release) > Semver(latest.beta)! {
          latest.beta = release.semver
        }
      case .canary:
        if Semver(release) > Semver(latest.canary)! {
          latest.canary = release.semver
        }
      }
    }

    return latest
  }
}

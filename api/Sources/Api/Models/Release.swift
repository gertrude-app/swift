import Duet
import Gertie

struct Release: Codable, Sendable {
  var id: Id
  var semver: String
  var channel: ReleaseChannel
  var signature: String
  var length: Int
  var revision: GitCommitSha
  var requirementPace: Int?
  var notes: String?
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id = .init(),
    semver: String,
    channel: ReleaseChannel,
    signature: String,
    length: Int,
    revision: GitCommitSha,
    requirementPace: Int? = nil,
    notes: String? = nil,
  ) {
    self.id = id
    self.semver = semver
    self.channel = channel
    self.signature = signature
    self.length = length
    self.revision = revision
    self.requirementPace = requirementPace
    self.notes = notes
  }
}

extension Semver {
  init(_ release: Release) {
    // releases are guaranteed to have a valid semver
    self.init(release.semver)!
  }

  func isBehind(_ release: Release) -> Bool {
    self < Semver(release)
  }
}

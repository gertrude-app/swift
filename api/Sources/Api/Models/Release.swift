import Duet
import Gertie

final class Release: Codable {
  var id: Id
  var semver: String
  var channel: ReleaseChannel
  var signature: String
  var length: Int
  var revision: GitCommitSha
  var requirementPace: Int?
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id = .init(),
    semver: String,
    channel: ReleaseChannel,
    signature: String,
    length: Int,
    revision: GitCommitSha,
    requirementPace: Int? = nil
  ) {
    self.id = id
    self.semver = semver
    self.channel = channel
    self.signature = signature
    self.length = length
    self.revision = revision
    self.requirementPace = requirementPace
  }
}

import Duet
import Gertie

final class Release: Codable {
  var id: Id
  var semver: String
  var channel: ReleaseChannel
  var signature: String
  var length: Int
  var appRevision: GitCommitSha
  var coreRevision: GitCommitSha
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id = .init(),
    semver: String,
    channel: ReleaseChannel,
    signature: String,
    length: Int,
    appRevision: GitCommitSha,
    coreRevision: GitCommitSha
  ) {
    self.id = id
    self.semver = semver
    self.channel = channel
    self.signature = signature
    self.length = length
    self.appRevision = appRevision
    self.coreRevision = coreRevision
  }
}

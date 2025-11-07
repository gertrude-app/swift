import Duet

struct AppBundleId: Codable, Sendable {
  var id: Id
  var bundleId: String
  var identifiedAppId: IdentifiedApp.Id
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id = .init(),
    identifiedAppId: IdentifiedApp.Id,
    bundleId: String,
  ) {
    self.id = id
    self.identifiedAppId = identifiedAppId
    self.bundleId = bundleId
  }
}

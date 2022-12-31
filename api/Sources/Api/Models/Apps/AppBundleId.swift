import Duet

final class AppBundleId: Codable {
  var id: Id
  var bundleId: String
  var identifiedAppId: IdentifiedApp.Id
  var createdAt = Date()
  var updatedAt = Date()

  var app = Parent<IdentifiedApp>.notLoaded

  init(
    id: Id = .init(),
    identifiedAppId: IdentifiedApp.Id,
    bundleId: String
  ) {
    self.id = id
    self.identifiedAppId = identifiedAppId
    self.bundleId = bundleId
  }
}

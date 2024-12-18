import Duet
import Gertie

struct UnidentifiedApp: Codable, Sendable {
  var id: Id
  var bundleId: String
  var bundleName: String?
  var localizedName: String?
  var launchable: Bool?
  var count: Int
  var createdAt = Date()

  init(
    id: Id = .init(),
    bundleId: String,
    bundleName: String? = nil,
    localizedName: String? = nil,
    launchable: Bool? = nil,
    count: Int = 1
  ) {
    self.id = id
    self.bundleId = bundleId
    self.bundleName = bundleName
    self.localizedName = localizedName
    self.launchable = launchable
    self.count = count
  }
}

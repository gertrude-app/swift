import Duet
import Gertie

struct UnidentifiedApp: Codable, Sendable {
  var id: Id
  var bundleId: String
  var count: Int
  var createdAt = Date()

  init(id: Id = .init(), bundleId: String, count: Int = 0) {
    self.id = id
    self.bundleId = bundleId
    self.count = count
  }
}

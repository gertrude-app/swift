import Duet
import Gertie

final class Browser: Codable {
  var id: Id
  var match: BrowserMatch
  var createdAt = Date()

  init(id: Id = .init(), match: BrowserMatch) {
    self.id = id
    self.match = match
  }
}

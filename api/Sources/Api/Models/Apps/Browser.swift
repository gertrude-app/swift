import Duet
import Gertie

struct Browser: Codable, Sendable {
  var id: Id
  var match: BrowserMatch
  var createdAt = Date()

  init(id: Id = .init(), match: BrowserMatch) {
    self.id = id
    self.match = match
  }
}

import Duet
import GertieIOS

extension IOSApp {
  struct BlockGroup: Codable, Sendable {
    var id: Id
    var name: String
    var description: String
    var createdAt = Date()
    var updatedAt = Date()

    init(id: Id = .init(), name: String, description: String) {
      self.id = id
      self.name = name
      self.description = description
    }
  }
}

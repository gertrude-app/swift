import Duet

struct StripeEvent: Codable, Sendable {
  var id: Id
  var json: String
  var createdAt = Date()

  init(id: Id = .init(), json: String) {
    self.id = id
    self.json = json
  }
}

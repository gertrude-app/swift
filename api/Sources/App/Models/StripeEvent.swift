import Duet

final class StripeEvent: Codable {
  var id: Id
  var json: String
  var createdAt = Date()

  init(
    id: Id = .init(),
    json: String
  ) {
    self.id = id
    self.json = json
  }
}

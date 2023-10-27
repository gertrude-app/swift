import Foundation

final class DeletedEntity: Codable {
  var id: Id
  var type: String
  var reason: String
  var data: String
  var createdAt = Date()

  init(id: Id = .init(), type: String, reason: String, data: String) {
    self.id = id
    self.type = type
    self.reason = reason
    self.data = data
  }
}

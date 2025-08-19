import Foundation

extension IOSApp {
  struct WebPolicyDomain: Codable, Sendable {
    var id: Id
    var deviceId: Device.Id
    var domain: String
    var createdAt = Date()
    var updatedAt = Date()

    init(id: Id = .init(), deviceId: Device.Id, domain: String) {
      self.id = id
      self.deviceId = deviceId
      self.domain = domain
    }
  }
}

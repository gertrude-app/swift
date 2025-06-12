import Duet
import GertieIOS

extension IOSApp {
  struct WebPolicy: Codable, Sendable {
    var id: Id
    var deviceId: Device.Id
    var policy: WebContentFilterPolicy
    var createdAt = Date()
    var updatedAt = Date()

    init(
      id: Id = .init(),
      deviceId: Device.Id,
      policy: WebContentFilterPolicy
    ) {
      self.id = id
      self.deviceId = deviceId
      self.policy = policy
    }
  }
}

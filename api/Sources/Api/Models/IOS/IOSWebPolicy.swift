import Duet
import GertieIOS

extension IOSApp {
  struct WebPolicy: Codable, Sendable {
    var id: Id
    var deviceId: Device.Id
    var webPolicy: GertieIOS.WebContentFilterPolicy
    var createdAt = Date()
    var updatedAt = Date()

    init(
      id: Id = .init(),
      deviceId: Device.Id,
      webPolicy: GertieIOS.WebContentFilterPolicy
    ) {
      self.id = id
      self.deviceId = deviceId
      self.webPolicy = webPolicy
    }
  }
}

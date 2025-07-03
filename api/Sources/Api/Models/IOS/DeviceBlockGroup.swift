import Duet
import GertieIOS

extension IOSApp {
  struct DeviceBlockGroup: Codable, Sendable {
    var id: Id
    var deviceId: Device.Id
    var blockGroupId: BlockGroup.Id
    var createdAt = Date()

    init(
      id: Id = .init(),
      deviceId: Device.Id,
      blockGroupId: BlockGroup.Id
    ) {
      self.id = id
      self.deviceId = deviceId
      self.blockGroupId = blockGroupId
    }
  }
}

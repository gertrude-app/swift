import DuetSQL
import GertieIOS

extension IOSApp {
  struct Device: Codable, Sendable {
    var id: Id
    var childId: Child.Id
    var vendorId: VendorId
    var deviceType: String
    var appVersion: String
    var iosVersion: String
    var createdAt = Date()
    var updatedAt = Date()

    init(
      id: Id? = nil,
      childId: Child.Id,
      vendorId: VendorId,
      deviceType: String,
      appVersion: String,
      iosVersion: String
    ) {
      self.id = id ?? .init(get(dependency: \.uuid)())
      self.childId = childId
      self.vendorId = vendorId
      self.deviceType = deviceType
      self.appVersion = appVersion
      self.iosVersion = iosVersion
    }
  }
}

// loaders

extension IOSApp.Device {
  func child(in db: any DuetSQL.Client) async throws -> Child {
    try await Child.query()
      .where(.id == self.childId)
      .first(in: db)
  }
}

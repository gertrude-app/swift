import Dependencies
import DuetSQL
import Tagged

extension IOSApp {
  struct Token: Codable, Sendable {
    var id: Id
    var deviceId: Device.Id
    var value: Value
    var createdAt = Date()
    var updatedAt = Date()

    init(id: Id = .init(), deviceId: Device.Id, value: Value? = nil) {
      self.id = id
      self.deviceId = deviceId
      self.value = value ?? .init(get(dependency: \.uuid)())
    }
  }
}

// loaders

extension IOSApp.Token {
  func device(in db: any DuetSQL.Client) async throws -> IOSApp.Device {
    try await IOSApp.Device.query()
      .where(.id == self.deviceId)
      .first(in: db)
  }
}

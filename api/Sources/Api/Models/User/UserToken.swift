import DuetSQL
import Tagged

final class UserToken: Codable {
  var id: Id
  var userId: User.Id
  var deviceId: Device.Id?
  var value: Value
  var createdAt = Date()
  var updatedAt = Date()
  var deletedAt: Date?

  var user = Parent<User>.notLoaded
  var device = OptionalParent<Device>.notLoaded

  init(
    id: Id = .init(),
    userId: User.Id,
    deviceId: Device.Id? = nil,
    value: Value = .init(rawValue: UUID.new())
  ) {
    self.id = id
    self.value = value
    self.userId = userId
    self.deviceId = deviceId
  }
}

// extensions

extension UserToken {
  typealias Value = Tagged<(UserToken, value: ()), UUID>
}

// loaders

extension UserToken {
  func device() async throws -> Device? {
    try await device.useLoaded(or: { () async throws -> Device? in
      guard let deviceId = deviceId else { return nil }
      return try await Current.db.query(Device.self)
        .where(.id == deviceId)
        .first()
    })
  }
}

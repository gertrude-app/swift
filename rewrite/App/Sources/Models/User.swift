import Foundation
import Tagged

public struct User: Equatable, Codable, Sendable {
  public var id: Id
  public var token: Token
  public var deviceId: DeviceId
  public var name: String
  public var keyloggingEnabled: Bool
  public var screenshotsEnabled: Bool
  public var screenshotFrequency: Int
  public var screenshotSize: Int
  public var connectedAt: Date

  public init(
    id: Id,
    token: Token,
    deviceId: DeviceId,
    name: String,
    keyloggingEnabled: Bool,
    screenshotsEnabled: Bool,
    screenshotFrequency: Int,
    screenshotSize: Int,
    connectedAt: Date = .init()
  ) {
    self.id = id
    self.token = token
    self.deviceId = deviceId
    self.name = name
    self.keyloggingEnabled = keyloggingEnabled
    self.screenshotsEnabled = screenshotsEnabled
    self.screenshotFrequency = screenshotFrequency
    self.screenshotSize = screenshotSize
    self.connectedAt = connectedAt
  }
}

// ids

public extension User {
  typealias Id = Tagged<User, UUID>
  typealias Token = Tagged<(user: User, token: ()), UUID>
  typealias DeviceId = Tagged<(user: User, deviceId: ()), UUID>
}

public extension Tagged where RawValue == UUID {
  init() {
    self.init(rawValue: .init())
  }
}

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

#if DEBUG
  extension User {
    static let mock = User(
      id: .init(uuidString: "00000000-0000-0000-0000-000000000000")!,
      token: .init(uuidString: "00000000-0000-0000-0000-000000000000")!,
      deviceId: .init(uuidString: "00000000-0000-0000-0000-000000000000")!,
      name: "Mock User",
      keyloggingEnabled: false,
      screenshotsEnabled: false,
      screenshotFrequency: 60,
      screenshotSize: 1000,
      connectedAt: .init(timeIntervalSince1970: 0)
    )

    static func mock(config: (inout Self) -> Void) -> Self {
      var mock = Self.mock
      config(&mock)
      return mock
    }
  }
#endif

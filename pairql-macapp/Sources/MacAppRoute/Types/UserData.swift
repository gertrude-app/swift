import Foundation

public struct UserData: Equatable, Codable, Sendable, PairOutput {
  public var id: UUID
  public var token: UUID
  public var deviceId: UUID
  public var name: String
  public var keyloggingEnabled: Bool
  public var screenshotsEnabled: Bool
  public var screenshotFrequency: Int
  public var screenshotSize: Int
  public var connectedAt: Date

  public init(
    id: UUID,
    token: UUID,
    deviceId: UUID,
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

public extension UserData {
  static let mock = Self(
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

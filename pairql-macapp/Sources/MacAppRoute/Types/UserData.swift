import Foundation
import Gertie

public struct UserData {
  public var id: UUID
  public var token: UUID
  public var deviceId: UUID
  public var name: String
  public var keyloggingEnabled: Bool
  public var screenshotsEnabled: Bool
  public var screenshotFrequency: Int
  public var screenshotSize: Int
  // `downtime` added in 2.5.0, but backwards compatible
  public var downtime: PlainTimeWindow?
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
    downtime: PlainTimeWindow? = nil,
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
    self.downtime = downtime
    self.connectedAt = connectedAt
  }
}

extension UserData: Equatable, Codable, Sendable, PairOutput {}

#if DEBUG
  extension UserData: Mocked {
    public static let mock = Self(
      id: UUID(),
      token: UUID(),
      deviceId: UUID(uuidString: "DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF")!,
      name: "Mock User",
      keyloggingEnabled: false,
      screenshotsEnabled: false,
      screenshotFrequency: 60,
      screenshotSize: 1000,
      connectedAt: .init(timeIntervalSince1970: 0)
    )

    public static var monitored: UserData {
      .mock {
        $0.keyloggingEnabled = true
        $0.screenshotsEnabled = true
        $0.screenshotFrequency = 60
        $0.screenshotSize = 1000
      }
    }

    public static var notMonitored: UserData {
      .mock {
        $0.keyloggingEnabled = false
        $0.screenshotsEnabled = false
        $0.screenshotFrequency = 60
        $0.screenshotSize = 1000
      }
    }

    public static let empty = Self(
      id: .init(uuidString: "00000000-0000-0000-0000-000000000000")!,
      token: .init(uuidString: "00000000-0000-0000-0000-000000000000")!,
      deviceId: .init(uuidString: "00000000-0000-0000-0000-000000000000")!,
      name: "",
      keyloggingEnabled: false,
      screenshotsEnabled: false,
      screenshotFrequency: 0,
      screenshotSize: 0,
      connectedAt: .init(timeIntervalSince1970: 0)
    )
  }
#endif

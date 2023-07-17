import DuetMock
import Foundation

@testable import Api

extension KeystrokeLine {
  static var mock: KeystrokeLine {
    KeystrokeLine(
      userDeviceId: .init(),
      appName: "@mock appName",
      line: "@mock line",
      createdAt: Current.date()
    )
  }

  static var empty: KeystrokeLine {
    KeystrokeLine(userDeviceId: .init(), appName: "", line: "", createdAt: Date())
  }

  static var random: KeystrokeLine {
    KeystrokeLine(
      userDeviceId: .init(),
      appName: "@random".random,
      line: "@random".random,
      createdAt: Current.date()
    )
  }
}

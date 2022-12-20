import DuetMock
import Foundation

@testable import App

extension KeystrokeLine {
  static var mock: KeystrokeLine {
    KeystrokeLine(
      deviceId: .init(),
      appName: "@mock appName",
      line: "@mock line",
      createdAt: Current.date()
    )
  }

  static var empty: KeystrokeLine {
    KeystrokeLine(deviceId: .init(), appName: "", line: "", createdAt: Date())
  }

  static var random: KeystrokeLine {
    KeystrokeLine(
      deviceId: .init(),
      appName: "@random".random,
      line: "@random".random,
      createdAt: Current.date()
    )
  }
}

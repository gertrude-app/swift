import DuetMock
import Foundation

@testable import Api

extension KeystrokeLine: Mock {
  public static var mock: KeystrokeLine {
    KeystrokeLine(
      userDeviceId: .init(),
      appName: "@mock appName",
      line: "@mock line",
      createdAt: Current.date()
    )
  }

  public static var empty: KeystrokeLine {
    KeystrokeLine(userDeviceId: .init(), appName: "", line: "", createdAt: Date())
  }

  public static var random: KeystrokeLine {
    KeystrokeLine(
      userDeviceId: .init(),
      appName: "@random".random,
      line: "@random".random,
      createdAt: Current.date()
    )
  }
}

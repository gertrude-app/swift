import Foundation
import Gertie

@testable import Api

extension KeystrokeLine: RandomMocked {
  public static var mock: KeystrokeLine {
    KeystrokeLine(
      userDeviceId: .init(),
      appName: "@mock appName",
      line: "@mock line",
      createdAt: .reference
    )
  }

  public static var empty: KeystrokeLine {
    KeystrokeLine(
      userDeviceId: .init(),
      appName: "",
      line: "",
      createdAt: .epoch
    )
  }

  public static var random: KeystrokeLine {
    KeystrokeLine(
      userDeviceId: .init(),
      appName: "@random".random,
      line: "@random".random,
      createdAt: Date()
    )
  }
}

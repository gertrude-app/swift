import Foundation
import Gertie

@testable import Api

extension KeystrokeLine: RandomMocked {
  public static var mock: KeystrokeLine {
    KeystrokeLine(
      computerUserId: .init(),
      appName: "@mock appName",
      line: "@mock line",
      createdAt: .reference
    )
  }

  public static var empty: KeystrokeLine {
    KeystrokeLine(
      computerUserId: .init(),
      appName: "",
      line: "",
      createdAt: .epoch
    )
  }

  public static var random: KeystrokeLine {
    KeystrokeLine(
      computerUserId: .init(),
      appName: "@random".random,
      line: "@random".random,
      flagged: Bool.random() ? Date() : nil,
      createdAt: Date()
    )
  }
}

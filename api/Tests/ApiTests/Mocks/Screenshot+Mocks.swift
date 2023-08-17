import Gertie

@testable import Api

extension Screenshot: RandomMocked {
  public static var mock: Screenshot {
    Screenshot(userDeviceId: .init(), url: "@mock url", width: 42, height: 42)
  }

  public static var empty: Screenshot {
    Screenshot(userDeviceId: .init(), url: "", width: 0, height: 0)
  }

  public static var random: Screenshot {
    Screenshot(userDeviceId: .init(), url: "@random".random, width: Int.random, height: Int.random)
  }
}

import DuetMock

@testable import App

extension Screenshot: Mock {
  public static var mock: Screenshot {
    Screenshot(deviceId: .init(), url: "@mock url", width: 42, height: 42)
  }

  public static var empty: Screenshot {
    Screenshot(deviceId: .init(), url: "", width: 0, height: 0)
  }

  public static var random: Screenshot {
    Screenshot(deviceId: .init(), url: "@random".random, width: Int.random, height: Int.random)
  }
}

import Gertie

@testable import Api

extension UserDevice: RandomMocked {
  public static var mock: UserDevice {
    UserDevice(
      userId: .init(),
      deviceId: .init(),
      appVersion: "@mock appVersion 1.0.0",
      username: "@mock username liljimmy",
      fullUsername: "@mock fullUsername Jimmy McStandard",
      numericId: 502
    )
  }

  public static var empty: UserDevice {
    UserDevice(
      userId: .init(),
      deviceId: .init(),
      appVersion: "",
      username: "",
      fullUsername: "",
      numericId: 0
    )
  }

  public static var random: UserDevice {
    UserDevice(
      userId: .init(),
      deviceId: .init(),
      appVersion: "@random".random,
      username: "@random".random,
      fullUsername: "@random".random,
      numericId: Int.random
    )
  }
}

import DuetMock

@testable import App

extension Device: Mock {
  public static var mock: Device {
    Device(
      userId: .init(),
      appVersion: "@mock appVersion",
      modelIdentifier: "@mock modelIdentifier",
      username: "@mock username",
      fullUsername: "@mock fullUsername",
      numericId: 42,
      serialNumber: "@mock serialNumber"
    )
  }

  public static var empty: Device {
    Device(
      userId: .init(),
      appVersion: "",
      modelIdentifier: "",
      username: "",
      fullUsername: "",
      numericId: 0,
      serialNumber: ""
    )
  }

  public static var random: Device {
    Device(
      userId: .init(),
      appVersion: "@random".random,
      modelIdentifier: "@random".random,
      username: "@random".random,
      fullUsername: "@random".random,
      numericId: Int.random,
      serialNumber: "@random".random
    )
  }
}

import Gertie

@testable import Api

extension Device: RandomMocked {
  public static var mock: Device {
    Device(
      parentId: .init(),
      customName: "@mock customName",
      modelIdentifier: "@mock modelIdentifier",
      serialNumber: "@mock serialNumber"
    )
  }

  public static var empty: Device {
    Device(
      parentId: .init(),
      customName: nil,
      modelIdentifier: "",
      serialNumber: ""
    )
  }

  public static var random: Device {
    Device(
      parentId: .init(),
      customName: "@random".random,
      modelIdentifier: "@random".random,
      serialNumber: "@random".random
    )
  }
}

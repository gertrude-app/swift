import DuetMock

@testable import Api

extension Device: Mock {
  public static var mock: Device {
    Device(
      adminId: .init(),
      customName: "@mock customName",
      modelIdentifier: "@mock modelIdentifier",
      serialNumber: "@mock serialNumber"
    )
  }

  public static var empty: Device {
    Device(
      adminId: .init(),
      customName: nil,
      modelIdentifier: "",
      serialNumber: ""
    )
  }

  public static var random: Device {
    Device(
      adminId: .init(),
      customName: "@random".random,
      modelIdentifier: "@random".random,
      serialNumber: "@random".random
    )
  }
}

import Gertie

@testable import Api

extension Computer: RandomMocked {
  public static var mock: Computer {
    Computer(
      parentId: .init(),
      customName: "@mock customName",
      modelIdentifier: "@mock modelIdentifier",
      serialNumber: "@mock serialNumber",
    )
  }

  public static var empty: Computer {
    Computer(
      parentId: .init(),
      customName: nil,
      modelIdentifier: "",
      serialNumber: "",
    )
  }

  public static var random: Computer {
    Computer(
      parentId: .init(),
      customName: "@random".random,
      modelIdentifier: "@random".random,
      serialNumber: "@random".random,
    )
  }
}

import Gertie

@testable import Api

extension ComputerUser: RandomMocked {
  public static var mock: ComputerUser {
    ComputerUser(
      childId: .init(),
      computerId: .init(),
      isAdmin: false,
      appVersion: "2.0.0", // must be valid semver
      username: "@mock username liljimmy",
      fullUsername: "@mock fullUsername Jimmy McStandard",
      numericId: 502,
    )
  }

  public static var empty: ComputerUser {
    ComputerUser(
      childId: .init(),
      computerId: .init(),
      isAdmin: false,
      appVersion: "0.0.0", // must be valid semver
      username: "",
      fullUsername: "",
      numericId: 0,
    )
  }

  public static var random: ComputerUser {
    ComputerUser(
      childId: .init(),
      computerId: .init(),
      isAdmin: false,
      appVersion: "3.\(Int.random(in: 10 ... 99)).\(Int.random(in: 10 ... 99))",
      username: "@random".random,
      fullUsername: "@random".random,
      numericId: Int.random,
    )
  }
}

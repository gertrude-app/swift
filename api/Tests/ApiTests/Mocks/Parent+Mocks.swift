import Gertie

@testable import Api

extension Parent: RandomMocked {
  public static var mock: Parent {
    Parent(email: "mock@mock.com", password: "@mock password")
  }

  public static var empty: Parent {
    Parent(email: "empty@empty.com", password: "")
  }

  public static var random: Parent {
    Parent(
      id: .init(.init()),
      email: .init(rawValue: "random@random\(Int.random).com"),
      password: "@random".random,
    )
  }
}

import Gertie

@testable import Api

extension Admin: RandomMocked {
  public static var mock: Admin {
    Admin(email: "mock@mock.com", password: "@mock password")
  }

  public static var empty: Admin {
    Admin(email: "empty@empty.com", password: "")
  }

  public static var random: Admin {
    Admin(
      id: .init(.init()),
      email: .init(rawValue: "random@random\(Int.random).com"),
      password: "@random".random
    )
  }
}

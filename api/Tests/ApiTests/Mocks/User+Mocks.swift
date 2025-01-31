import Gertie

@testable import Api

extension User: RandomMocked {
  public static var mock: User {
    User(parentId: .init(), name: "@mock name")
  }

  public static var empty: User {
    User(parentId: .init(), name: "")
  }

  public static var random: User {
    User(parentId: .init(), name: "@random".random)
  }
}

import Gertie

@testable import Api

extension Child: RandomMocked {
  public static var mock: Child {
    Child(parentId: .init(), name: "@mock name")
  }

  public static var empty: Child {
    Child(parentId: .init(), name: "")
  }

  public static var random: Child {
    Child(parentId: .init(), name: "@random".random)
  }
}

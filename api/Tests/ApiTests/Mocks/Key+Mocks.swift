import protocol Gertie.RandomMocked

@testable import Api

extension Key: RandomMocked {
  public static var mock: Key {
    Key(keychainId: .init(), key: .mock)
  }

  public static var empty: Key {
    Key(keychainId: .init(), key: .empty)
  }

  public static var random: Key {
    Key(keychainId: .init(), key: .random)
  }
}

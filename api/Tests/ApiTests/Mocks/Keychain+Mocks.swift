import Gertie

@testable import Api

extension Keychain: RandomMocked {
  public static var mock: Keychain {
    Keychain(
      parentId: .init(),
      name: "@mock name",
      isPublic: false,
      description: "@mock description"
    )
  }

  public static var empty: Keychain {
    Keychain(parentId: .init(), name: "", isPublic: false)
  }

  public static var random: Keychain {
    Keychain(
      parentId: .init(),
      name: "@mock name".random,
      isPublic: Bool.random(),
      description: "@mock description".random
    )
  }
}

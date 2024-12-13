import Gertie

@testable import Api

extension IdentifiedApp: RandomMocked {
  public static var mock: IdentifiedApp {
    IdentifiedApp(name: "@mock name", slug: "mock-slug", launchable: true)
  }

  public static var empty: IdentifiedApp {
    IdentifiedApp(name: "", slug: "", launchable: false)
  }

  public static var random: IdentifiedApp {
    IdentifiedApp(
      name: "@random".random,
      slug: "random-slug-\(Int.random)",
      launchable: Bool.random()
    )
  }
}

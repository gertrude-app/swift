import Gertie

@testable import Api

extension IdentifiedApp: RandomMocked {
  public static var mock: IdentifiedApp {
    IdentifiedApp(bundleName: "@mock name", slug: "mock-slug", launchable: true)
  }

  public static var empty: IdentifiedApp {
    IdentifiedApp(bundleName: "", slug: "", launchable: false)
  }

  public static var random: IdentifiedApp {
    IdentifiedApp(
      bundleName: "@random".random,
      slug: "random-slug-\(Int.random)",
      launchable: Bool.random()
    )
  }
}

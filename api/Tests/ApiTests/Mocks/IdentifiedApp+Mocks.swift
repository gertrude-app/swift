import Gertie

@testable import Api

extension IdentifiedApp: RandomMocked {
  public static var mock: IdentifiedApp {
    IdentifiedApp(name: "@mock name", slug: "mock-slug", selectable: true)
  }

  public static var empty: IdentifiedApp {
    IdentifiedApp(name: "", slug: "", selectable: false)
  }

  public static var random: IdentifiedApp {
    IdentifiedApp(
      name: "@random".random,
      slug: "random-slug-\(Int.random)",
      selectable: Bool.random()
    )
  }
}

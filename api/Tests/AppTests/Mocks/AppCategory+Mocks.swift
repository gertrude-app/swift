import DuetMock

@testable import App

extension AppCategory: Mock {
  public static var mock: AppCategory {
    AppCategory(name: "@mock name", slug: "mock-slug")
  }

  public static var empty: AppCategory {
    AppCategory(name: "", slug: "")
  }

  public static var random: AppCategory {
    AppCategory(name: "@random".random, slug: "random-slug-\(Int.random)")
  }
}

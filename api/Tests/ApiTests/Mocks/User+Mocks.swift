import DuetMock

@testable import Api

extension User: Mock {
  public static var mock: User {
    User(adminId: .init(), name: "@mock name")
  }

  public static var empty: User {
    User(adminId: .init(), name: "")
  }

  public static var random: User {
    User(adminId: .init(), name: "@random".random)
  }
}

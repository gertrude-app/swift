import PairQL

public enum AuthedAdminRoute: PairRoute {
  case getUser(GetUser.Input)
  case getUsers

  public static let router = OneOf {
    Route(/Self.getUser) {
      Operation(GetUser.self)
      Body(.json(GetUser.Input.self))
    }
    Route(/Self.getUsers) {
      Operation(GetUsers.self)
    }
  }
}

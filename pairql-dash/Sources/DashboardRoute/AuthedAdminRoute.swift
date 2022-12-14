import PairQL

public enum AuthedAdminRoute: PairRoute {
  case getUser(GetUser.Input)
  case getUsers
  case saveUser(SaveUser.Input)
  case deleteUser(DeleteUser.Input)
  case getUserActivityDays(GetUserActivityDays.Input)

  public static let router = OneOf {
    Route(/Self.getUser) {
      Operation(GetUser.self)
      Body(.json(GetUser.Input.self))
    }
    Route(/Self.getUsers) {
      Operation(GetUsers.self)
    }
    Route(/Self.saveUser) {
      Operation(SaveUser.self)
      Body(.json(SaveUser.Input.self))
    }
    Route(/Self.deleteUser) {
      Operation(DeleteUser.self)
      Body(.json(DeleteUser.Input.self))
    }
    Route(/Self.getUserActivityDays) {
      Operation(GetUserActivityDays.self)
      Body(.json(GetUserActivityDays.Input.self))
    }
  }
}

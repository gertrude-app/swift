import PairQL

public enum UnauthedRoute: PairRoute {
  case connectApp(ConnectApp.Input)
}

public extension UnauthedRoute {
  static let router = OneOf {
    Route(/Self.connectApp) {
      Operation(ConnectApp.self)
      Body(.json(ConnectApp.Input.self))
    }
  }
}

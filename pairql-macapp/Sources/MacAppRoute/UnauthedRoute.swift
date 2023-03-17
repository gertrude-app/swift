import PairQL

public enum UnauthedRoute: PairRoute {
  case connectApp(ConnectApp.Input)
  case connectUser(ConnectUser.Input)
}

public extension UnauthedRoute {
  static let router: AnyParserPrinter<URLRequestData, UnauthedRoute> = OneOf {
    Route(/Self.connectApp) {
      Operation(ConnectApp.self)
      Body(.json(ConnectApp.Input.self))
    }
    Route(/Self.connectUser) {
      Operation(ConnectUser.self)
      Body(.json(ConnectUser.Input.self))
    }
  }
  .eraseToAnyParserPrinter()
}

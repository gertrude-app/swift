import PairQL

public enum UnauthedRoute: PairRoute {
  case connectApp(ConnectApp.Input)
  case connectUser(ConnectUser.Input)
  case latestAppVersion(LatestAppVersion.Input)
  case logUnexpectedError(LogUnexpectedError.Input)
  case recentAppVersions
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
    Route(/Self.latestAppVersion) {
      Operation(LatestAppVersion.self)
      Body(.json(LatestAppVersion.Input.self))
    }
    Route(/Self.logUnexpectedError) {
      Operation(LogUnexpectedError.self)
      Body(.json(LogUnexpectedError.Input.self))
    }
    Route(/Self.recentAppVersions) {
      Operation(RecentAppVersions.self)
    }
  }
  .eraseToAnyParserPrinter()
}

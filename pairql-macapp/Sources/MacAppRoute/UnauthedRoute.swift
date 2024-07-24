import PairQL

public enum UnauthedRoute: PairRoute {
  case connectUser(ConnectUser.Input)
  case latestAppVersion(LatestAppVersion.Input)
  case logInterestingEvent(LogInterestingEvent.Input)
  case recentAppVersions
}

public extension UnauthedRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, UnauthedRoute> = OneOf {
    Route(/Self.connectUser) {
      Operation(ConnectUser.self)
      Body(.json(ConnectUser.Input.self))
    }
    Route(/Self.latestAppVersion) {
      Operation(LatestAppVersion.self)
      Body(.json(LatestAppVersion.Input.self))
    }
    Route(/Self.logInterestingEvent) {
      Operation(LogInterestingEvent.self)
      Body(.json(LogInterestingEvent.Input.self))
    }
    Route(/Self.recentAppVersions) {
      Operation(RecentAppVersions.self)
    }
  }
  .eraseToAnyParserPrinter()
}

import PairQL

public enum UnauthedRoute: PairRoute {
  case connectUser(ConnectUser.Input)
  case latestAppVersion(LatestAppVersion.Input)
  case logInterestingEvent(LogInterestingEvent.Input)
  case recentAppVersions
  case trustedTime
}

public extension UnauthedRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, UnauthedRoute> = OneOf {
    Route(.case(Self.connectUser)) {
      Operation(ConnectUser.self)
      Body(.json(ConnectUser.Input.self))
    }
    Route(.case(Self.latestAppVersion)) {
      Operation(LatestAppVersion.self)
      Body(.json(LatestAppVersion.Input.self))
    }
    Route(.case(Self.logInterestingEvent)) {
      Operation(LogInterestingEvent.self)
      Body(.json(LogInterestingEvent.Input.self))
    }
    Route(.case(Self.recentAppVersions)) {
      Operation(RecentAppVersions.self)
    }
    Route(.case(Self.trustedTime)) {
      Operation(TrustedTime.self)
    }
  }
  .eraseToAnyParserPrinter()
}

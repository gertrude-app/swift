import PairQL

public enum UnauthedRoute: PairRoute {
  case logPodcastEvent(LogPodcastEvent.Input)
  case podcastProducts
  case createDatabaseUpload(CreateDatabaseUpload.Input)
}

public extension UnauthedRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, UnauthedRoute> = OneOf {
    Route(.case(Self.logPodcastEvent)) {
      Operation(LogPodcastEvent.self)
      Body(.json(LogPodcastEvent.Input.self))
    }
    Route(.case(Self.podcastProducts)) {
      Operation(PodcastProducts.self)
    }
    Route(.case(Self.createDatabaseUpload)) {
      Operation(CreateDatabaseUpload.self)
      Body(.json(CreateDatabaseUpload.Input.self))
    }
  }
  .eraseToAnyParserPrinter()
}

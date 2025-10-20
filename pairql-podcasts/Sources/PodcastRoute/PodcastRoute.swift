import Foundation
import PairQL

public enum PodcastRoute: PairRoute {
  case unauthed(UnauthedRoute)
}

public extension PodcastRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, PodcastRoute> = OneOf {
    Route(.case(Self.unauthed)) {
      UnauthedRoute.router
    }
  }
  .eraseToAnyParserPrinter()
}

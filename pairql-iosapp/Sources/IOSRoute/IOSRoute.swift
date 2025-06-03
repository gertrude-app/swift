import Foundation
import PairQL

public enum IOSRoute: PairRoute {
  case authed(UUID, AuthedRoute)
  case unauthed(UnauthedRoute)
}

public extension IOSRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, IOSRoute> = OneOf {
    Route(.case(Self.authed)) {
      Headers { Field("X-DeviceToken") { UUID.parser() } }
      AuthedRoute.router
    }
    Route(.case(Self.unauthed)) {
      UnauthedRoute.router
    }
  }
  .eraseToAnyParserPrinter()
}

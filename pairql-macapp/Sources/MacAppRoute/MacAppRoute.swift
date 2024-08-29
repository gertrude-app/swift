import Foundation
import PairQL

public enum MacAppRoute: PairRoute {
  case userAuthed(UUID, AuthedUserRoute)
  case unauthed(UnauthedRoute)
}

public extension MacAppRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, MacAppRoute> = OneOf {
    Route(.case(Self.userAuthed)) {
      Headers { Field("X-UserToken") { UUID.parser() } }
      AuthedUserRoute.router
    }
    Route(.case(Self.unauthed)) {
      UnauthedRoute.router
    }
  }
  .eraseToAnyParserPrinter()
}

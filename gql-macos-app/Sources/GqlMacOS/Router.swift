import Foundation
import URLRouting

@_exported import GertieQL

public enum MacAppRoute: Equatable {
  case userAuthed(UUID, AuthedUserRoute)
  case unauthed(UnAuthedRoute)
}

public extension MacAppRoute {
  static let router = OneOf {
    Route(.case(Self.userAuthed)) {
      Headers { Field("X-UserToken") { UUID.parser() } }
      AuthedUserRoute.router
    }
    Route(.case(Self.unauthed)) {
      UnAuthedRoute.router
    }
  }
}

public enum UnAuthedRoute: Equatable {
  case register
}

public extension UnAuthedRoute {
  static let router = OneOf {
    Route(.case(Self.register)) {
      Path { "register" }
    }
  }
}

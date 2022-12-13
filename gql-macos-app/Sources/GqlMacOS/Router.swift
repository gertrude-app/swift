import Foundation

@_exported import GertieQL

public enum MacAppRoute: Equatable {
  case userAuthed(UUID, AuthedUserRoute)
  case unauthed(UnAuthedRoute)
}

public extension MacAppRoute {
  static let router = OneOf {
    Route(/Self.userAuthed) {
      Headers { Field("X-UserToken") { UUID.parser() } }
      AuthedUserRoute.router
    }
    Route(/Self.unauthed) {
      UnAuthedRoute.router
    }
  }
}

public enum UnAuthedRoute: Equatable {
  case register
}

public extension UnAuthedRoute {
  static let router = OneOf {
    Route(/Self.register) {
      Path { "register" } // todo
    }
  }
}

import Foundation
import URLRouting

public enum GertieQL {}

public extension GertieQL {
  enum Route: Equatable {
    case dashboard(Dashboard)
    case macApp(MacApp)
  }
}

public extension GertieQL.Route {
  static let router = OneOf {
    Route(.case(Self.macApp)) {
      Method.post
      Path { "macos-app" }
      MacApp.router
    }
    Route(.case(Self.dashboard)) {
      Method.post
      Path { "dashboard" }
      Dashboard.router
    }
  }
}

public extension GertieQL.Route {
  enum MacApp: Equatable {
    case userTokenAuthed(UUID, UserTokenAuthed)
    case unauthed(UnAuthed)
  }
}

public extension GertieQL.Route.MacApp {
  static let router = OneOf {
    Route(.case(Self.userTokenAuthed)) {
      Headers { Field("X-UserToken") { UUID.parser() } }
      UserTokenAuthed.router
    }
    Route(.case(Self.unauthed)) {
      UnAuthed.router
    }
  }
}

public extension GertieQL.Route.MacApp {
  enum UnAuthed: Equatable {
    case register
  }
}

public extension GertieQL.Route.MacApp.UnAuthed {
  static let router = OneOf {
    Route(.case(Self.register)) {
      Path { "register" }
    }
  }
}

// dashboard

public extension GertieQL.Route {
  enum Dashboard: Equatable {
    case placeholder
  }
}

public extension GertieQL.Route.Dashboard {
  static let router = OneOf {
    Route(.case(Self.placeholder)) {
      Path { "placeholder" }
    }
  }
}

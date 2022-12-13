import PairQL

public enum UnauthedRoute: PairRoute {
  case register
}

public extension UnauthedRoute {
  static let router = OneOf {
    Route(/Self.register) {
      Path { "register" } // todo
    }
  }
}

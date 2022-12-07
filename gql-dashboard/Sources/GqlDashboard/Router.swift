import Foundation
import URLRouting

@_exported import GertieQL

public enum DashboardRoute: Equatable {
  case placeholder
}

public extension DashboardRoute {
  static let router = OneOf {
    Route(.case(Self.placeholder)) {
      Path { "placeholder" }
    }
  }
}

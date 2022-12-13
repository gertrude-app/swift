import Foundation
import PairQL

public enum DashboardRoute: PairRoute {
  case adminAuthed(UUID, AuthedAdminRoute)
  case unauthed(UnauthedRoute)

  public static let router = OneOf {
    Route(/Self.adminAuthed) {
      Headers { Field("X-AdminToken") { UUID.parser() } }
      AuthedAdminRoute.router
    }
    Route(/Self.unauthed) {
      UnauthedRoute.router
    }
  }
}

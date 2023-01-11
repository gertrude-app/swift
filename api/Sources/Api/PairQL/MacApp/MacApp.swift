import DuetSQL
import MacAppRoute
import Vapor

extension MacAppRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {

    case .unauthed(let unauthed):
      fatalError("not implemented \(unauthed)")

    case .userAuthed(let uuid, let userRoute):
      let token = try await Current.db.query(UserToken.self)
        .where(.value == uuid)
        .first()
      let userContext = UserContext(
        requestId: context.requestId,
        dashboardUrl: context.dashboardUrl,
        user: try await token.user(),
        token: token
      )
      return try await AuthedUserRoute.respond(to: userRoute, in: userContext)
    }
  }
}

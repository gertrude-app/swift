import DuetSQL
import MacAppRoute
import Vapor

struct MacAppContext: ResolverContext {
  let requestId: String
}

extension MacAppRoute: RouteResponder {
  static func respond(to route: Self, in context: MacAppContext) async throws -> Response {
    switch route {

    case .unauthed(let unauthed):
      fatalError("not implemented \(unauthed)")

    case .userAuthed(let uuid, let userRoute):
      let token = try await Current.db.query(UserToken.self)
        .where(.value == uuid)
        .first()
      let user = try await Current.db.query(User.self)
        .where(.id == token.userId)
        .first()
      let userContext = UserContext(requestId: context.requestId, user: user)
      return try await AuthedUserRoute.respond(to: userRoute, in: userContext)
    }
  }
}

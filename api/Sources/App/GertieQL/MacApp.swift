import DuetSQL
import Vapor

extension MacApp: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
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
      let userContext = UserAuthed.Context(request: context.request, user: user)
      return try await UserAuthed.respond(to: userRoute, in: userContext)
    }
  }
}

import Vapor

extension MacApp: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {

    case .unauthed(let unauthed):
      fatalError("not implemented \(unauthed)")

    case .userAuthed(let uuid, let userRoute):
      let user = try await getUser(token: uuid)
      let userContext = UserAuthed.Context(request: context.request, user: user)
      return try await UserAuthed.respond(to: userRoute, in: userContext)
    }
  }
}

// think: get user from db
func getUser(token: UUID) async throws -> UUID {
  token
}

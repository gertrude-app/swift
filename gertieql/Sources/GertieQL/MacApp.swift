import Foundation

// think: vapor request
struct Request {}

typealias GRoute = GertieQL.Route

struct Context {
  let request: Request
}

extension GRoute.MacApp: RouteResolver {
  static func resolve(route: Self, context: Context) async throws -> Codable {
    switch route {

    case .unauthed(let unauthed):
      fatalError("unauthed \(unauthed)")

    case .userAuthed(let uuid, let userRoute):
      let user = try await getUser(token: uuid)
      return try await UserAuthed.resolve(
        route: userRoute,
        context: .init(request: context.request, user: user)
      )
    }
  }
}

// think: get user from db
func getUser(token: UUID) async throws -> UUID {
  token
}

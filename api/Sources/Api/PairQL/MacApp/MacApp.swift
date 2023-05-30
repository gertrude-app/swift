import DuetSQL
import MacAppRoute
import Vapor

extension MacAppRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {

    case .unauthed(let unauthed):
      switch unauthed {
      case .connectApp(let input):
        let output = try await ConnectApp.resolve(with: input, in: context)
        return try await respond(with: output)
      case .connectUser(let input):
        let output = try await ConnectUser.resolve(with: input, in: context)
        return try await respond(with: output)
      case .latestAppVersion(let input):
        let output = try await LatestAppVersion.resolve(with: input, in: context)
        return try await respond(with: output)
      case .recentAppVersions:
        let output = try await RecentAppVersions.resolve(in: context)
        return try await respond(with: output)
      }

    case .userAuthed(let uuid, let userRoute):
      let token = try await Current.db.query(UserToken.self)
        .where(.value == uuid)
        .first(orThrow: context.error(
          id: "6e88d0de",
          type: .unauthorized,
          debugMessage: "user token not found",
          appTag: .userTokenNotFound
        ))

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

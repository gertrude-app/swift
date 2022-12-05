import DuetSQL
import Vapor

extension UserAuthed: RouteResponder {
  struct Context {
    let request: App.Context.Request
    let user: User
  }

  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {

    case .createSignedScreenshotUpload(let input):
      let output = try await CreateSignedScreenshotUpload.resolve(for: input, in: context)
      return try await respond(with: output)

    case .getUsersAdminAccountStatus:
      let output = try await GetUsersAdminAccountStatus.resolve(in: context)
      return try await respond(with: output)
    }
  }
}

extension UserAuthed.GetUsersAdminAccountStatus: NoInputPairResolver {
  static func resolve(in context: UserAuthed.Context) async throws -> Output {
    let admin = try await Current.db.query(Admin.self)
      .where(.id == context.user.adminId)
      .first()

    return .init(status: admin.accountStatus)
  }
}

extension UserAuthed.CreateSignedScreenshotUpload: PairResolver {
  static func resolve(
    for input: Input,
    in context: UserAuthed.Context
  ) async throws -> Output {
    fatalError()
  }
}

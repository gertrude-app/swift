import Vapor

extension UserAuthed: RouteResponder {
  struct Context {
    let request: Request
    let user: UUID
  }

  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {

    case .createSignedScreenshotUpload(let input):
      let output = try await CreateSignedScreenshotUpload.resolve(for: input, in: context)
      return try await respond(with: output)

    case .getUsersAdminAccountStatus:
      fatalError()
    }
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

import Foundation

extension GRoute.MacApp.UserAuthed: RouteResolver {
  struct Context {
    let request: Request
    let user: UUID
  }

  static func resolve(route: Self, context: Context) async throws -> Codable {
    switch route {

    case .createSignedScreenshotUpload(let input):
      return try await CreateSignedScreenshotUpload.resolve(input, context)

    case .getUsersAdminAccountStatus:
      fatalError()
    }
  }
}

extension GRoute.MacApp.UserAuthed.CreateSignedScreenshotUpload: PairResolver {
  static func resolve(
    _ input: Input,
    _ context: GRoute.MacApp.UserAuthed.Context
  ) async throws -> Output {
    fatalError()
  }
}

protocol PairResolver: Pair {
  associatedtype Context
  static func resolve(_ input: Input, _ context: Context) async throws -> Output
}

protocol RouteResolver {
  associatedtype Context
  static func resolve(route: Self, context: Context) async throws -> Codable
}

import DuetSQL
import MacAppRoute
import Vapor

struct UserContext: ResolverContext {
  let requestId: String
  let user: User
}

extension AuthedUserRoute: RouteResponder {
  static func respond(to route: Self, in context: UserContext) async throws -> Response {
    switch route {

    case .createSignedScreenshotUpload(let input):
      let output = try await CreateSignedScreenshotUpload.resolve(with: input, in: context)
      return try await respond(with: output)

    case .getAccountStatus:
      let output = try await GetAccountStatus.resolve(in: context)
      return try await respond(with: output)
    }
  }
}

extension GetAccountStatus: NoInputResolver {
  static func resolve(in context: UserContext) async throws -> Output {
    let admin = try await Current.db.query(Admin.self)
      .where(.id == context.user.adminId)
      .first()

    return .init(status: admin.accountStatus)
  }
}

extension CreateSignedScreenshotUpload: Resolver {
  static func resolve(
    with input: Input,
    in context: AuthedUserRoute.Context
  ) async throws -> Output {
    fatalError()
  }
}

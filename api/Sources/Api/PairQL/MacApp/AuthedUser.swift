import MacAppRoute
import Vapor

struct UserContext: ResolverContext {
  let requestId: String
  let user: User
  let token: UserToken

  func device() async throws -> Device {
    guard let device = try await token.device() else {
      throw Abort(.notFound, reason: "missing device")
    }
    return device
  }
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
    case .refreshRules:
      let output = try await RefreshRules.resolve(in: context)
      return try await respond(with: output)
    }
  }
}

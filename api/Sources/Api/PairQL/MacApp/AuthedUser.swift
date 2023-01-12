import MacAppRoute
import Vapor

struct UserContext: ResolverContext {
  let requestId: String
  let dashboardUrl: String
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
    case .refreshRules(let input):
      let output = try await RefreshRules.resolve(with: input, in: context)
      return try await respond(with: output)
    case .createKeystrokeLines(let input):
      let output = try await CreateKeystrokeLines.resolve(with: input, in: context)
      return try await respond(with: output)
    case .createNetworkDecisions(let input):
      let output = try await CreateNetworkDecisions.resolve(with: input, in: context)
      return try await respond(with: output)
    case .createSuspendFilterRequest(let input):
      let output = try await CreateSuspendFilterRequest.resolve(with: input, in: context)
      return try await respond(with: output)
    case .createUnlockRequests(let input):
      let output = try await CreateUnlockRequests.resolve(with: input, in: context)
      return try await respond(with: output)
    }
  }
}

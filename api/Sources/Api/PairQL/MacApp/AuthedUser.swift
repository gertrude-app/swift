import MacAppRoute
import Vapor

struct UserContext: ResolverContext {
  let requestId: String
  let dashboardUrl: String
  let user: User
  let token: UserToken

  func userDevice() async throws -> UserDevice {
    guard let userDevice = try await token.userDevice() else {
      throw Abort(.notFound, reason: "missing user device")
    }
    return userDevice
  }
}

extension AuthedUserRoute: RouteResponder {
  static func respond(
    to route: Self,
    in context: UserContext
  ) async throws -> Response {
    switch route {
    case .checkIn(let input):
      let output = try await CheckIn.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .createSignedScreenshotUpload(let input):
      let output = try await CreateSignedScreenshotUpload.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getAccountStatus:
      let output = try await GetAccountStatus.resolve(in: context)
      return try await self.respond(with: output)
    case .getUserData:
      let output = try await GetUserData.resolve(in: context)
      return try await self.respond(with: output)
    case .refreshRules(let input):
      let output = try await RefreshRules.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .createKeystrokeLines(let input):
      let output = try await CreateKeystrokeLines.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .createSuspendFilterRequest(let input):
      let output = try await CreateSuspendFilterRequest.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .createUnlockRequests_v2(let input):
      let output = try await CreateUnlockRequests_v2.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .reportBrowsers(let input):
      let output = try await ReportBrowsers.resolve(with: input, in: context)
      return try await self.respond(with: output)
    }
  }
}

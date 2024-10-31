import Dependencies
import MacAppRoute
import Vapor

struct UserContext: ResolverContext {
  let requestId: String
  let dashboardUrl: String
  let user: User
  let token: UserToken

  @Dependency(\.uuid) var uuid
  @Dependency(\.env) var env
  @Dependency(\.db) var db

  func userDevice() async throws -> UserDevice {
    try await self.token.userDevice(in: self.db)
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
    case .logFilterEvents(let input):
      let output = try await LogFilterEvents.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .logSecurityEvent(let input):
      let output = try await LogSecurityEvent.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .createKeystrokeLines(let input):
      let output = try await CreateKeystrokeLines.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .createSuspendFilterRequest_v2(let input):
      let output = try await CreateSuspendFilterRequest_v2.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .createUnlockRequests_v3(let input):
      let output = try await CreateUnlockRequests_v3.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .reportBrowsers(let input):
      let output = try await ReportBrowsers.resolve(with: input, in: context)
      return try await self.respond(with: output)
    }
  }
}

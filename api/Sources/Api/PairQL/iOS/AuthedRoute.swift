import Dependencies
import IOSRoute
import Vapor

extension IOSApp {
  struct ChildContext: ResolverContext {
    let requestId: String
    let dashboardUrl: String
    let child: Child
    let device: IOSApp.Device

    @Dependency(\.db) var db
  }
}

extension AuthedRoute: RouteResponder {
  static func respond(
    to route: Self,
    in context: IOSApp.ChildContext
  ) async throws -> Response {
    switch route {
    case .blockRules_v3(let input):
      let output = try await BlockRules_v3.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .createSuspendFilterRequest(let input):
      let output = try await CreateSuspendFilterRequest.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .pollFilterSuspensionDecision(let input):
      let output = try await PollFilterSuspensionDecision.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .screenshotUploadUrl(let input):
      let output = try await ScreenshotUploadUrl.resolve(with: input, in: context)
      return try await self.respond(with: output)
    }
  }
}

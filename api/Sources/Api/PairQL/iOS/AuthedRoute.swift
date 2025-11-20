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
  static func respond(to route: Self, in ctx: IOSApp.ChildContext) async throws -> Response {
    switch route {
    case .connectedRules_b1(let input):
      let output = try await ConnectedRules_b1.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    case .connectedRules(let input):
      let output = try await ConnectedRules.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    case .createSuspendFilterRequest(let input):
      let output = try await CreateSuspendFilterRequest.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    case .pollFilterSuspensionDecision(let input):
      let output = try await PollFilterSuspensionDecision.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    case .screenshotUploadUrl(let input):
      let output = try await ScreenshotUploadUrl.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    }
  }
}

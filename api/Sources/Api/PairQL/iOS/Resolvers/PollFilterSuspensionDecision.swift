import IOSRoute

extension PollFilterSuspensionDecision: Resolver {
  static func resolve(with input: Input, in context: IOSApp.ChildContext) async throws -> Output {
    let request = try await context.db.find(IOSApp.SuspendFilterRequest.Id(input))
    return request.status
  }
}

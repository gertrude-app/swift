import IOSRoute

/// testflight only: v1.4.0 - present
extension BlockRules_v3: Resolver {
  static func resolve(with input: Input, in context: IOSApp.ChildContext) async throws -> Output {
    .init(blockRules: [], webPolicy: .blockAll)
  }
}

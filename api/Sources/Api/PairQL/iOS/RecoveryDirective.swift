import IOSRoute

extension RecoveryDirective: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    await with(dependency: \.slack)
      .internal(.info, "Received iOS *RecoveryDirective* request, input: `\(input)`")
    return .init(directive: nil)
  }
}

import IOSRoute

extension RecoveryDirective: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    await with(dependency: \.slack)
      .internal(.info, "Received iOS *RecoveryDirective* request, input: `\(input)`")

    if let retryUuid = context.env.getUUID("IOS_RECOVERY_DIRECTIVE_RETRY_UUID"),
       retryUuid == input.vendorId {
      return .init(directive: "retry")
    }

    return .init(directive: nil)
  }
}

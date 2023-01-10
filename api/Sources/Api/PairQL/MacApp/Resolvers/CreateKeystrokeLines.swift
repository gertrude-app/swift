import MacAppRoute

extension CreateKeystrokeLines: Resolver {
  static func resolve(
    with inputs: [KeystrokeLineInput],
    in context: UserContext
  ) async throws -> Output {
    let device = try await context.device()
    let keystrokeLines = inputs.map { input in
      KeystrokeLine(
        deviceId: device.id,
        appName: input.appName,
        line: input.line,
        createdAt: input.time
      )
    }
    try await Current.db.create(keystrokeLines)
    return .success
  }
}

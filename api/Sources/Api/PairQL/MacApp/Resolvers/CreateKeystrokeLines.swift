import MacAppRoute

extension CreateKeystrokeLines: Resolver {
  static func resolve(
    with inputs: [KeystrokeLineInput],
    in context: UserContext
  ) async throws -> Output {
    let userDevice = try await context.userDevice()
    let keystrokeLines = inputs.map { input in
      KeystrokeLine(
        userDeviceId: userDevice.id,
        appName: input.appName,
        line: input.line,
        filterSuspended: input.filterSuspended ?? false,
        createdAt: input.time
      )
    }
    try await Current.db.create(keystrokeLines)
    return .success
  }
}

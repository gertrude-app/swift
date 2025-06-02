import MacAppRoute

extension CreateKeystrokeLines: Resolver {
  static func resolve(
    with inputs: [KeystrokeLineInput],
    in context: UserContext
  ) async throws -> Output {
    let computerUser = try await context.computerUser()
    let keystrokeLines = inputs.map { input in
      KeystrokeLine(
        computerUserId: computerUser.id,
        appName: input.appName,
        line: input.line.replacingOccurrences(of: "\0", with: "\u{FFFD}"),
        filterSuspended: input.filterSuspended ?? false,
        createdAt: input.time
      )
    }
    try await context.db.create(keystrokeLines)
    return .success
  }
}

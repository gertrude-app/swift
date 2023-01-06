import DuetSQL
import TypescriptPairQL

struct DeleteActivityItems: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Input: TypescriptPairInput {
    let userId: User.Id
    let keystrokeLineIds: [KeystrokeLine.Id]
    let screenshotIds: [Screenshot.Id]
  }
}

// resolver

extension DeleteActivityItems: Resolver {
  static func resolve(
    with input: Input,
    in context: AdminContext
  ) async throws -> Output {
    let user = try await context.verifiedUser(from: input.userId)
    let devicesIds = (try await user.devices()).map(\.id)
    async let keystrokes = try await Current.db.query(KeystrokeLine.self)
      .where(.deviceId |=| devicesIds)
      .where(.id |=| input.keystrokeLineIds)
      .delete()
    async let screenshots = Current.db.query(Screenshot.self)
      .where(.deviceId |=| devicesIds)
      .where(.id |=| input.screenshotIds)
      .delete()
    _ = try await (keystrokes, screenshots)
    return .success
  }
}

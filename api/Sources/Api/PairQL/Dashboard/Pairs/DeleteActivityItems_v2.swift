import DuetSQL
import TypescriptPairQL

struct DeleteActivityItems_v2: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Input: TypescriptPairInput {
    let keystrokeLineIds: [KeystrokeLine.Id]
    let screenshotIds: [Screenshot.Id]
  }
}

// resolver

extension DeleteActivityItems_v2: Resolver {
  static func resolve(
    with input: Input,
    in context: AdminContext
  ) async throws -> Output {
    let deviceIds = try await context.userDevices().map(\.id)
    async let keystrokes = try await Current.db.query(KeystrokeLine.self)
      .where(.deviceId |=| deviceIds)
      .where(.id |=| input.keystrokeLineIds)
      .delete()
    async let screenshots = Current.db.query(Screenshot.self)
      .where(.deviceId |=| deviceIds)
      .where(.id |=| input.screenshotIds)
      .delete()
    _ = try await (keystrokes, screenshots)
    return .success
  }
}

import DuetSQL
import PairQL

struct DeleteActivityItems_v2: Pair {
  static var auth: ClientAuth = .admin

  struct Input: PairInput {
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
    let userDeviceIds = try await context.userDevices().map(\.id)
    async let keystrokes = try await Current.db.query(KeystrokeLine.self)
      .where(.userDeviceId |=| userDeviceIds)
      .where(.id |=| input.keystrokeLineIds)
      .delete()
    async let screenshots = Current.db.query(Screenshot.self)
      .where(.userDeviceId |=| userDeviceIds)
      .where(.id |=| input.screenshotIds)
      .delete()
    _ = try await (keystrokes, screenshots)
    return .success
  }
}

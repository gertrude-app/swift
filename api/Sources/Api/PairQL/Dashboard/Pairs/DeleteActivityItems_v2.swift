import DuetSQL
import PairQL

struct DeleteActivityItems_v2: Pair {
  static let auth: ClientAuth = .admin

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
    async let keystrokes = try await KeystrokeLine.query()
      .where(.userDeviceId |=| userDeviceIds)
      .where(.id |=| input.keystrokeLineIds)
      .delete()
    async let screenshots = Screenshot.query()
      .where(.userDeviceId |=| userDeviceIds)
      .where(.id |=| input.screenshotIds)
      .delete()
    _ = try await (keystrokes, screenshots)
    return .success
  }
}

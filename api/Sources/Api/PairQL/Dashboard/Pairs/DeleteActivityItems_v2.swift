import DuetSQL
import PairQL

struct DeleteActivityItems_v2: Pair {
  static let auth: ClientAuth = .parent

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
    let computerUserIds = try await context.computerUsers().map(\.id)
    async let keystrokes = try await KeystrokeLine.query()
      .where(.computerUserId |=| computerUserIds)
      .where(.id |=| input.keystrokeLineIds)
      .where(.isNull(.flagged))
      .delete(in: context.db)
    async let screenshots = Screenshot.query()
      .where(.computerUserId |=| computerUserIds)
      .where(.id |=| input.screenshotIds)
      .where(.isNull(.flagged))
      .delete(in: context.db)
    _ = try await (keystrokes, screenshots)
    return .success
  }
}

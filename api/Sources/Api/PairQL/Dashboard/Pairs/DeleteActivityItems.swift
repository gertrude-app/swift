import DuetSQL
import TypescriptPairQL

struct DeleteActivityItems: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Input: TypescriptPairInput {
    let keystrokeLineIds: [KeystrokeLine.Id]
    let screenshotIds: [Screenshot.Id]
  }
}

// resolver

extension DeleteActivityItems: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    async let keystrokes = try await Current.db.query(KeystrokeLine.self)
      .where(.id |=| input.keystrokeLineIds)
      .delete()
    async let screenshots = Current.db.query(Screenshot.self)
      .where(.id |=| input.screenshotIds)
      .delete()
    _ = try await (keystrokes, screenshots)
    return .success
  }
}

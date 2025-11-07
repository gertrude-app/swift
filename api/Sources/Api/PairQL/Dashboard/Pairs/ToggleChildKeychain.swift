import DuetSQL
import Gertie
import PairQL

struct ToggleChildKeychain: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var keychainId: Keychain.Id
    var childId: Child.Id
  }
}

// resolver

extension ToggleChildKeychain: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let existingChildKeychain = try? await ChildKeychain.query()
      .where(.keychainId == input.keychainId)
      .where(.childId == input.childId)
      .first(in: context.db)

    if let existingChildKeychain {
      // if the child already is has the keychain assigned, unassign it
      try await context.db.delete(existingChildKeychain.id)
    } else {
      // if the child does not have the keychain assigned, assign it
      let newChildKeychain = ChildKeychain(
        childId: input.childId,
        keychainId: input.keychainId,
      )
      try await context.db.create(newChildKeychain)
    }
    return .success
  }
}

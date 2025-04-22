import DuetSQL
import Gertie
import PairQL

struct ToggleChildKeychain: Pair {
  static let auth: ClientAuth = .admin

  struct Input: PairInput {
    var keychainId: Keychain.Id
    var childId: User.Id
  }
}

// resolver

extension ToggleChildKeychain: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    let existingChildKeychain = try? await UserKeychain.query()
      .where(.keychainId == input.keychainId)
      .where(.childId == input.childId)
      .first(in: context.db)

    if let existingChildKeychain {
      // if the child already is has the keychain assigned, unassign it
      try await context.db.delete(existingChildKeychain.id)
    } else {
      // if the child does not have the keychain assigned, assign it
      let newChildKeychain = UserKeychain(
        childId: input.childId,
        keychainId: input.keychainId
      )
      try await context.db.create(newChildKeychain)
    }
    return .success
  }
}

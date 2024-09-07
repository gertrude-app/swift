import PairQL

struct SaveKeychain: Pair {
  static let auth: ClientAuth = .admin

  struct Input: PairInput {
    let isNew: Bool
    let id: Keychain.Id
    let name: String
    let description: String?
  }
}

// resolver

extension SaveKeychain: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    if input.isNew {
      let keychain = try await context.db.create(Keychain(
        id: input.id,
        authorId: context.admin.id,
        name: input.name,
        isPublic: false,
        description: input.description
      ))
      dashSecurityEvent(.keychainCreated, "name: \(keychain.name)", in: context)
    } else {
      var keychain = try await context.db.find(input.id)
      keychain.name = input.name
      keychain.description = input.description
      try await context.db.update(keychain)
    }
    return .success
  }
}

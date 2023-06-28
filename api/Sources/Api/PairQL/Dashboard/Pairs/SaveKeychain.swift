import PairQL

struct SaveKeychain: Pair {
  static var auth: ClientAuth = .admin

  struct Input: PairInput {
    let isNew: Bool
    let id: Keychain.Id
    let name: String
    let description: String?
    let isPublic: Bool
  }
}

// resolver

extension SaveKeychain: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    if input.isNew {
      try await Current.db.create(Keychain(
        id: input.id,
        authorId: context.admin.id,
        name: input.name,
        isPublic: input.isPublic,
        description: input.description
      ))
    } else {
      let keychain = try await Current.db.find(input.id)
      keychain.name = input.name
      keychain.isPublic = input.isPublic
      keychain.description = input.description
      try await Current.db.update(keychain)
    }
    return .success
  }
}

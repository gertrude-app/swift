import Foundation
import Gertie
import PairQL

struct SaveKey: Pair {
  static let auth: ClientAuth = .admin

  struct Input: PairInput {
    var isNew: Bool
    var id: Key.Id
    var keychainId: Keychain.Id
    var key: Gertie.Key
    var comment: String?
    var expiration: Date?
  }
}

// resolver

extension SaveKey: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    let keychain = try await context.admin.keychain(input.keychainId)
    if input.isNew {
      var key = try await Current.db.create(Key(
        id: input.id,
        keychainId: keychain.id,
        key: input.key,
        comment: input.comment,
        deletedAt: input.expiration
      ))
      // duet struggles creating models with `deletedAt` set
      if let expiration = input.expiration {
        key.deletedAt = expiration
        try await Current.db.update(key)
      }
    } else {
      var key = try await Current.db.find(input.id)
      key.comment = input.comment
      key.key = input.key
      key.deletedAt = input.expiration
      try await Current.db.update(key)
    }
    try await Current.connectedApps.notify(.keychainUpdated(keychain.id))
    return .success
  }
}

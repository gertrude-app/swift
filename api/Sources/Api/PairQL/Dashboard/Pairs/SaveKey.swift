import Foundation
import Shared
import TypescriptPairQL

struct SaveKey: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Input: TypescriptPairInput {
    let isNew: Bool
    let id: Key.Id
    let keychainId: Keychain.Id
    let key: Shared.Key
    let comment: String?
    let expiration: Date?
  }
}

// resolver

extension SaveKey: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    fatalError("todo")
  }
}

import Foundation
import Gertie
import PairQL

struct GetAdminKeychains: Pair {
  static let auth: ClientAuth = .admin

  struct Key: PairNestable {
    let id: Api.Key.Id
    let keychainId: Api.Keychain.Id
    let comment: String?
    let expiration: Date?
    let key: Gertie.Key
  }

  struct AdminKeychain: PairNestable, PairOutput {
    let summary: KeychainSummary
    let keys: [Key]
  }

  typealias Output = [AdminKeychain]
}

// resolver

extension GetAdminKeychains: NoInputResolver {
  static func resolve(in context: AdminContext) async throws -> Output {
    let models = try await context.admin.keychains(in: context.db)
    var keychains: [AdminKeychain] = []
    for model in models {
      keychains.append(try await .init(from: model, in: context))
    }
    return keychains
  }
}

// extensions

extension GetAdminKeychains.AdminKeychain {
  init(from model: Api.Keychain, in context: AdminContext) async throws {
    let keys = try await model.keys(in: context.db)
    self.init(
      summary: try await .init(from: model),
      keys: keys.map { .init(from: $0, keychainId: model.id) }
    )
  }
}

extension GetAdminKeychains.Key {
  init(from model: Api.Key, keychainId: Api.Keychain.Id) {
    id = model.id
    comment = model.comment
    expiration = model.deletedAt
    key = model.key
    self.keychainId = keychainId
  }
}

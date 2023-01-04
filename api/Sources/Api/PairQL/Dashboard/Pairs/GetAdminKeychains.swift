import Foundation
import Shared
import TypescriptPairQL

struct GetAdminKeychains: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Key: TypescriptNestable, GlobalType {
    let id: Api.Key.Id
    let keychainId: Api.Keychain.Id
    let comment: String?
    let expiration: Date?
    let key: Shared.Key
  }

  struct AdminKeychain: TypescriptNestable, PairOutput, GlobalType {
    let summary: KeychainSummary
    let keys: [Key]
  }

  typealias Output = [AdminKeychain]
}

// resolver

extension GetAdminKeychains: NoInputResolver {
  static func resolve(in context: AdminContext) async throws -> Output {
    let models = try await context.admin.keychains()
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
    let keys = try await model.keys()
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

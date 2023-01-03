import Foundation
import Shared
import TypescriptPairQL

enum Pql {
  struct Key: TypescriptNestable, GlobalType {
    let id: Api.Key.Id
    let comment: String?
    let expiration: Date?
    let key: Shared.Key
  }

  struct Keychain: TypescriptNestable, PairOutput, GlobalType {
    let id: Api.Keychain.Id
    let name: String
    let description: String?
    let isPublic: Bool
    let authorId: Admin.Id
    let keys: [Key]
  }
}

struct GetAdminKeychains: TypescriptPair {
  static var auth: ClientAuth = .admin
  typealias Output = [Pql.Keychain]
}

// resolver

extension GetAdminKeychains: NoInputResolver {
  static func resolve(in context: AdminContext) async throws -> Output {
    let models = try await context.admin.keychains()
    var keychains: [Pql.Keychain] = []
    for model in models {
      keychains.append(try await .init(from: model, in: context))
    }
    return keychains
  }
}

// extensions

extension Pql.Keychain {
  init(from model: Api.Keychain, in context: AdminContext) async throws {
    let keys = try await model.keys()
    id = model.id
    name = model.name
    description = model.description
    isPublic = model.isPublic
    authorId = model.authorId
    self.keys = keys.map { .init(from: $0) }
  }
}

extension Pql.Key {
  init(from model: Api.Key) {
    id = model.id
    comment = model.comment
    expiration = model.deletedAt
    key = model.key
  }
}

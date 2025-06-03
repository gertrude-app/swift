import Dependencies
import DuetSQL
import Foundation
import Gertie
import PairQL

struct GetAdminKeychains: Pair {
  static let auth: ClientAuth = .parent

  struct Key: PairNestable {
    let id: Api.Key.Id
    let keychainId: Api.Keychain.Id
    let comment: String?
    let expiration: Date?
    let key: Gertie.Key
  }

  struct Child: PairNestable {
    let id: Api.User.Id
    let name: String
  }

  struct AdminKeychain: PairNestable, PairOutput {
    let summary: KeychainSummary
    let children: [User.Id]
    let keys: [Key]
  }

  struct Output: PairNestable, PairOutput {
    let keychains: [AdminKeychain]
    let children: [Child]
  }
}

// resolver

extension GetAdminKeychains: NoInputResolver {
  static func resolve(in context: AdminContext) async throws -> Output {
    let models = try await context.admin.keychains(in: context.db)
    var keychains: [AdminKeychain] = []
    for model in models {
      try await keychains.append(.init(from: model, in: context))
    }
    return try await .init(
      keychains: keychains,
      children: .init(parentId: context.admin.id)
    )
  }
}

// extensions

extension GetAdminKeychains.AdminKeychain {
  init(from model: Api.Keychain, in context: AdminContext) async throws {
    let keys = try await model.keys(in: context.db)
    try await self.init(
      summary: .init(from: model),
      children: .init(from: model, parentId: context.admin.id),
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

extension [GetAdminKeychains.Child] {
  init(parentId: Admin.Id) async throws {
    @Dependency(\.db) var db
    let children = try await User.query()
      .where(.parentId == parentId)
      .all(in: db)
    self = children.map {
      .init(from: $0)
    }
  }
}

extension [User.Id] {
  init(from model: Api.Keychain, parentId: Admin.Id) async throws {
    @Dependency(\.db) var db
    let userKeychains = try await UserKeychain.query()
      .where(.keychainId == model.id)
      .all(in: db)
    let users = try await User.query()
      .where(.id |=| userKeychains.map(\.childId))
      .where(.parentId == parentId)
      .all(in: db)
    self = users.map(\.id)
  }
}

extension GetAdminKeychains.Child {
  init(from model: User) {
    id = model.id
    name = model.name
  }
}

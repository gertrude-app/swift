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
    let id: Api.Child.Id
    let name: String
  }

  struct AdminKeychain: PairNestable, PairOutput {
    let summary: KeychainSummary
    let children: [Api.Child.Id]
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
    let models = try await context.parent.keychains(in: context.db)
    var keychains: [AdminKeychain] = []
    for model in models {
      try await keychains.append(.init(from: model, in: context))
    }
    return try await .init(
      keychains: keychains,
      children: .init(parentId: context.parent.id)
    )
  }
}

// extensions

extension GetAdminKeychains.AdminKeychain {
  init(from model: Api.Keychain, in context: AdminContext) async throws {
    let keys = try await model.keys(in: context.db)
    try await self.init(
      summary: .init(from: model),
      children: .init(from: model, parentId: context.parent.id),
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
    let children = try await Child.query()
      .where(.parentId == parentId)
      .all(in: db)
    self = children.map {
      .init(from: $0)
    }
  }
}

extension [Child.Id] {
  init(from model: Api.Keychain, parentId: Admin.Id) async throws {
    @Dependency(\.db) var db
    let childKeychains = try await ChildKeychain.query()
      .where(.keychainId == model.id)
      .all(in: db)
    let children = try await Child.query()
      .where(.id |=| childKeychains.map(\.childId))
      .where(.parentId == parentId)
      .all(in: db)
    self = children.map(\.id)
  }
}

extension GetAdminKeychains.Child {
  init(from model: Child) {
    id = model.id
    name = model.name
  }
}

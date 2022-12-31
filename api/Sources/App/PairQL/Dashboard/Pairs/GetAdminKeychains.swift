import Foundation
import Shared
import TypescriptPairQL

struct GetAdminKeychains: TypescriptPair {
  static var auth: ClientAuth = .admin

  typealias Output = [Keychain]

  struct Keychain: TypescriptNestable, PairOutput {
    struct Key: TypescriptNestable {
      struct Domain: TypescriptNestable {
        public var domain: String
        public var scope: AppScope
      }

      struct AnySubdomain: TypescriptNestable {
        public var domain: String
        public var scope: AppScope
      }

      struct Skeleton: TypescriptNestable {
        public var scope: AppScope.Single
      }

      struct DomainRegex: TypescriptNestable {
        public var pattern: String
        public var scope: AppScope
      }

      struct Path: TypescriptNestable {
        public var path: String
        public var scope: AppScope
      }

      struct IpAddress: TypescriptNestable {
        public var ipAddress: String
        public var scope: AppScope
      }

      typealias SharedKey = Union6<
        Key.Domain,
        Key.AnySubdomain,
        Key.Skeleton,
        Key.DomainRegex,
        Key.Path,
        Key.IpAddress
      >

      let id: App.Key.Id
      let comment: String?
      let expiration: Date?
      let key: SharedKey
    }

    let id: App.Keychain.Id
    let name: String
    let description: String?
    let isPublic: Bool
    let authorId: Admin.Id
    let keys: [Key]
  }
}

// resolver

extension GetAdminKeychains: NoInputResolver {
  static func resolve(in context: AdminContext) async throws -> Output {
    let models = try await context.admin.keychains()
    var keychains: [GetAdminKeychains.Keychain] = []
    for model in models {
      keychains.append(try await .init(from: model, in: context))
    }
    return keychains
  }
}

// extensions

extension GetAdminKeychains.Keychain {
  init(from model: App.Keychain, in context: AdminContext) async throws {
    let keys = try await model.keys()
    id = model.id
    name = model.name
    description = model.description
    isPublic = model.isPublic
    authorId = model.authorId
    self.keys = keys.map { .init(from: $0) }
  }
}

extension GetAdminKeychains.Keychain.Key {
  init(from model: App.Key) {
    let sharedKey: SharedKey
    switch model.key {
    case .domain(let domain, let scope):
      sharedKey = .t1(.init(domain: domain.string, scope: scope))
    case .anySubdomain(let domain, let scope):
      sharedKey = .t2(.init(domain: domain.string, scope: scope))
    case .skeleton(let scope):
      sharedKey = .t3(.init(scope: scope))
    case .domainRegex(let pattern, let scope):
      sharedKey = .t4(.init(pattern: pattern.string, scope: scope))
    case .path(let path, let scope):
      sharedKey = .t5(.init(path: path.domain.string, scope: scope))
    case .ipAddress(let ipAddress, let scope):
      sharedKey = .t6(.init(ipAddress: ipAddress.string, scope: scope))
    }
    self.init(id: model.id, comment: model.comment, expiration: model.deletedAt, key: sharedKey)
  }
}

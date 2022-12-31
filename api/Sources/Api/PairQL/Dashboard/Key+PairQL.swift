import Foundation
import Shared
import TypescriptPairQL
import Vapor

enum PQL {
  struct Key: TypescriptNestable {
    struct Domain: TypescriptNestable {
      var domain: String
      var scope: AppScope
    }

    struct AnySubdomain: TypescriptNestable {
      var domain: String
      var scope: AppScope
    }

    struct Skeleton: TypescriptNestable {
      var scope: AppScope.Single
    }

    struct DomainRegex: TypescriptNestable {
      var pattern: String
      var scope: AppScope
    }

    struct Path: TypescriptNestable {
      var path: String
      var scope: AppScope
    }

    struct IpAddress: TypescriptNestable {
      var ipAddress: String
      var scope: AppScope
    }

    typealias SharedKey = Union6<
      Key.Domain,
      Key.AnySubdomain,
      Key.Skeleton,
      Key.DomainRegex,
      Key.Path,
      Key.IpAddress
    >

    let id: Api.Key.Id
    let comment: String?
    let expiration: Date?
    let key: SharedKey
  }
}

// extensions

extension PQL.Key {
  init(from model: Api.Key) {
    let sharedKey: PQL.Key.SharedKey
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

extension Shared.Key.Domain {
  init(validating string: String) throws {
    guard let domain = Self(string) else {
      throw Abort(.badRequest, reason: "Invalid domain: \(string)")
    }
    self = domain
  }
}

extension Shared.Key {
  init(from pqlKey: PQL.Key.SharedKey) throws {
    switch pqlKey {
    case .t1(let key):
      self = try .domain(domain: .init(validating: key.domain), scope: key.scope)
    case .t2(let key):
      self = try .anySubdomain(domain: .init(validating: key.domain), scope: key.scope)
    case .t3(let skeleton):
      fatalError("not implemented")
    case .t4(let domainRegex):
      fatalError("not implemented")
    case .t5(let path):
      fatalError("not implemented")
    case .t6(let ipAddress):
      fatalError("not implemented")
    }
  }
}

import Foundation
import Gertie
import PairQL

struct SaveKey: Pair {
  static let auth: ClientAuth = .parent

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
    let keychain = try await context.admin.keychain(input.keychainId, in: context.db)
    if input.isNew {
      try await context.db.create(Key(
        id: input.id,
        keychainId: keychain.id,
        key: input.key,
        comment: input.comment,
        deletedAt: input.expiration
      ))
      let detail = "key opening \(input.key.simpleDescription) added to keychain '\(keychain.name)'"
      dashSecurityEvent(.keyCreated, detail, in: context)
    } else {
      var key = try await context.db.find(input.id)
      key.comment = input.comment
      key.key = input.key
      key.deletedAt = input.expiration
      try await context.db.update(key)
    }
    try await with(dependency: \.websockets)
      .send(.userUpdated, to: .usersWith(keychain: keychain.id))
    return .success
  }
}

extension Gertie.Key {
  var simpleDescription: String {
    switch self {
    case .anySubdomain(let domain, let scope):
      "any subdomain of \(domain.string) for \(scope.simpleDescription)"
    case .domain(let domain, let scope):
      "domain \(domain.string) for \(scope.simpleDescription)"
    case .domainRegex(let pattern, let scope):
      "domains matching pattern: \(pattern.string) for \(scope.simpleDescription)"
    case .ipAddress(let ipAddress, let scope):
      "ip \(ipAddress.string) for \(scope.simpleDescription)"
    case .path(let path, let scope):
      "path \(path.domain.string)\(path.path) for \(scope.simpleDescription)"
    case .skeleton(let scope):
      "unrestricted access for \(scope.simpleDescription)"
    }
  }
}

extension AppScope {
  var simpleDescription: String {
    switch self {
    case .unrestricted:
      "unrestricted"
    case .webBrowsers:
      "all web browsers"
    case .single(let single):
      "single app, \(single.simpleDescription)"
    }
  }
}

extension AppScope.Single {
  var simpleDescription: String {
    switch self {
    case .bundleId(let bundleId):
      "bundle=\(bundleId)"
    case .identifiedAppSlug(let slug):
      "slug=\(slug)"
    }
  }
}

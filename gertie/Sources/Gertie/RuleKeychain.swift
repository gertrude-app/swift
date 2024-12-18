import Foundation

public struct RuleKeychain {
  public let id: UUID
  public let schedule: RuleSchedule?
  public let keys: [RuleKey]

  public init(
    id: UUID = .init(),
    schedule: RuleSchedule? = nil,
    keys: [RuleKey]
  ) {
    self.id = id
    self.schedule = schedule
    self.keys = keys
  }
}

public struct RuleKey {
  public let id: UUID
  public let key: Key

  public init(id: UUID = .init(), key: Key) {
    self.id = id
    self.key = key
  }
}

// extensions

public extension Array where Element == RuleKeychain {
  var numKeys: Int { self.map(\.keys.count).reduce(0, +) }
}

// conformances

extension RuleKeychain: Codable, Sendable, Equatable, Hashable {}
extension RuleKey: Codable, Sendable, Equatable, Hashable {}

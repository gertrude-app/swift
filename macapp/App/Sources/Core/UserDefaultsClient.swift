import XCore

public struct UserDefaultsClient: Sendable {
  public var setString: @Sendable (String, String) -> Void
  public var getString: @Sendable (String) -> String?
  public var remove: @Sendable (String) -> Void
  public var removeAll: @Sendable () -> Void

  public init(
    setString: @escaping @Sendable (String, String) -> Void,
    getString: @escaping @Sendable (String) -> String?,
    remove: @escaping @Sendable (String) -> Void,
    removeAll: @escaping @Sendable () -> Void
  ) {
    self.setString = setString
    self.getString = getString
    self.remove = remove
    self.removeAll = removeAll
  }

  public func loadJson<T: Decodable>(at key: String, decoding type: T.Type) throws -> T? {
    try getString(key).flatMap { try JSON.decode($0, as: T.self) }
  }

  public func saveJson<T: Encodable>(from value: T, at key: String) throws {
    setString(try JSON.encode(value), key)
  }
}

public extension UserDefaultsClient {
  static let liveValue = Self(
    setString: { UserDefaults.standard.set($0, forKey: $1) },
    getString: { UserDefaults.standard.string(forKey: $0) },
    remove: { UserDefaults.standard.removeObject(forKey: $0) },
    removeAll: {
      UserDefaults.standard.dictionaryRepresentation().keys.forEach { key in
        UserDefaults.standard.removeObject(forKey: key)
      }
    }
  )
}

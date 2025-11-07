import Dependencies
import Foundation
import os.log
import XCore

public struct UserDefaultsClient: Sendable {
  public var setInt: @Sendable (String, Int) -> Void
  public var getInt: @Sendable (String) -> Int
  public var setString: @Sendable (String, String) -> Void
  public var getString: @Sendable (String) -> String?
  public var remove: @Sendable (String) -> Void
  public var removeAll: @Sendable () -> Void

  public init(
    setInt: @escaping @Sendable (String, Int) -> Void,
    getInt: @escaping @Sendable (String) -> Int,
    setString: @escaping @Sendable (String, String) -> Void,
    getString: @escaping @Sendable (String) -> String?,
    remove: @escaping @Sendable (String) -> Void,
    removeAll: @escaping @Sendable () -> Void,
  ) {
    self.setInt = setInt
    self.getInt = getInt
    self.setString = setString
    self.getString = getString
    self.remove = remove
    self.removeAll = removeAll
  }

  public func setString(key: String, value: String) {
    self.setString(key, value)
  }

  public func loadJson<T: Decodable>(at key: String, decoding type: T.Type) throws -> T? {
    try self.getString(key).flatMap { try JSON.decode($0, as: T.self) }
  }

  public func saveJson(from value: some Encodable, at key: String) throws {
    try self.setString(key: key, value: JSON.encode(value))
  }
}

extension UserDefaultsClient: DependencyKey {
  public static let liveValue = Self(
    setInt: { UserDefaults.standard.set($1, forKey: $0) },
    getInt: { UserDefaults.standard.integer(forKey: $0) },
    setString: {
      #if DEBUG
        if $0.starts(with: "{") || $0.starts(with: "[") {
          os_log("[G•] ERROR reversed key/value in UserDefaultsClient.setString")
          fatalError("reversed key/value in UserDefaultsClient.setString")
        }
      #endif
      return UserDefaults.standard.set($1, forKey: $0)
    },
    getString: { UserDefaults.standard.string(forKey: $0) },
    remove: { UserDefaults.standard.removeObject(forKey: $0) },
    removeAll: {
      for key in UserDefaults.standard.dictionaryRepresentation().keys {
        UserDefaults.standard.removeObject(forKey: key)
      }
    },
  )
}

extension UserDefaultsClient: TestDependencyKey {
  public static let testValue = Self(
    setInt: unimplemented("UserDefaultsClient.setInt", placeholder: ()),
    getInt: unimplemented("UserDefaultsClient.getInt", placeholder: 0),
    setString: unimplemented("UserDefaultsClient.setString", placeholder: ()),
    getString: unimplemented("UserDefaultsClient.getString", placeholder: nil),
    remove: unimplemented("UserDefaultsClient.remove", placeholder: ()),
    removeAll: unimplemented("UserDefaultsClient.removeAll", placeholder: ()),
  )
  public static let mock = Self(
    setInt: { _, _ in },
    getInt: { _ in 0 },
    setString: { _, _ in },
    getString: { _ in nil },
    remove: { _ in },
    removeAll: {},
  )
}

public extension DependencyValues {
  var userDefaults: UserDefaultsClient {
    get { self[UserDefaultsClient.self] }
    set { self[UserDefaultsClient.self] = newValue }
  }
}

#if DEBUG
  public extension UserDefaultsClient {
    static let failing = Self.testValue
  }
#endif

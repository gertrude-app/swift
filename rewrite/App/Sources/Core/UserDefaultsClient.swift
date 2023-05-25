import Dependencies
import Foundation

public struct UserDefaultsClient: Sendable {
  public var setString: @Sendable (String, String) -> Void
  public var getString: @Sendable (String) -> String?
  public var remove: @Sendable (String) -> Void

  public init(
    setString: @escaping @Sendable (String, String) -> Void,
    getString: @escaping @Sendable (String) -> String?,
    remove: @escaping @Sendable (String) -> Void
  ) {
    self.setString = setString
    self.getString = getString
    self.remove = remove
  }
}

extension UserDefaultsClient: DependencyKey {
  public static let liveValue = Self(
    setString: { UserDefaults.standard.set($0, forKey: $1) },
    getString: { UserDefaults.standard.string(forKey: $0) },
    remove: { UserDefaults.standard.removeObject(forKey: $0) }
  )
}

extension UserDefaultsClient: TestDependencyKey {
  public static let testValue = Self(
    setString: { _, _ in },
    getString: { _ in nil },
    remove: { _ in }
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
    static let failing = Self(
      setString: unimplemented("UserDefaultsClient.setString"),
      getString: unimplemented("UserDefaultsClient.getString"),
      remove: unimplemented("UserDefaultsClient.remove")
    )
  }
#endif

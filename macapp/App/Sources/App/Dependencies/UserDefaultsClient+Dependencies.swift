import Core
import Dependencies
import Foundation

extension UserDefaultsClient: DependencyKey {}

extension UserDefaultsClient: TestDependencyKey {
  public static let testValue = Self(
    setString: { _, _ in },
    getString: { _ in nil },
    remove: { _ in },
    removeAll: {}
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
      remove: unimplemented("UserDefaultsClient.remove"),
      removeAll: unimplemented("UserDefaultsClient.removeAll")
    )
  }
#endif

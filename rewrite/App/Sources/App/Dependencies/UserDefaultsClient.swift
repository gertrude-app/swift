import Dependencies
import Foundation

struct UserDefaultsClient: Sendable {
  var setString: @Sendable (String, String) -> Void
  var getString: @Sendable (String) -> String?
  var remove: @Sendable (String) -> Void
}

extension UserDefaultsClient: DependencyKey {
  static let liveValue = Self(
    setString: { UserDefaults.standard.set($0, forKey: $1) },
    getString: { UserDefaults.standard.string(forKey: $0) },
    remove: { UserDefaults.standard.removeObject(forKey: $0) }
  )
}

extension UserDefaultsClient: TestDependencyKey {
  static let testValue = Self(
    setString: { _, _ in },
    getString: { _ in nil },
    remove: { _ in }
  )
}

extension DependencyValues {
  var userDefaults: UserDefaultsClient {
    get { self[UserDefaultsClient.self] }
    set { self[UserDefaultsClient.self] = newValue }
  }
}

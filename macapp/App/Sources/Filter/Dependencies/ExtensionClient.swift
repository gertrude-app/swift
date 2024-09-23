import Dependencies
import Foundation

struct ExtensionClient: Sendable {
  var version: @Sendable () -> String
}

extension ExtensionClient: DependencyKey {
  static let liveValue = Self(
    version: {
      Bundle.main
        .infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }
  )
}

extension ExtensionClient: TestDependencyKey {
  static let testValue = Self(
    version: unimplemented("ExtensionClient.version", placeholder: "2.5.0")
  )
  static let mock = Self(
    version: { "1.0.0" }
  )
}

extension DependencyValues {
  var filterExtension: ExtensionClient {
    get { self[ExtensionClient.self] }
    set { self[ExtensionClient.self] = newValue }
  }
}

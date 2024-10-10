import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct StorageClient: Sendable {
  var object: @Sendable (_ forKey: String) -> Any?
  var set: @Sendable (Any?, _ forKey: String) -> Void
}

extension StorageClient: DependencyKey {
  public static let liveValue = StorageClient(
    object: {
      key in UserDefaults.standard.object(forKey: key)
    },
    set: { value, key in
      UserDefaults.standard.set(value, forKey: key)
    }
  )
}

extension StorageClient: TestDependencyKey {
  public static let testValue = StorageClient()
}

extension DependencyValues {
  var storage: StorageClient {
    get { self[StorageClient.self] }
    set { self[StorageClient.self] = newValue }
  }
}

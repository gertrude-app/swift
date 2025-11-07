import ClientInterfaces
import Dependencies
import Foundation

public struct UpdaterClient: Sendable {
  public var triggerUpdate: @Sendable (String) async throws -> Void

  public init(triggerUpdate: @escaping @Sendable (String) async throws -> Void) {
    self.triggerUpdate = triggerUpdate
  }
}

extension UpdaterClient: TestDependencyKey {
  public static let testValue = Self(
    triggerUpdate: unimplemented("UpdaterClient.triggerUpdate"),
  )
  public static let mock = Self(
    triggerUpdate: { _ in },
  )
}

public extension DependencyValues {
  var updater: UpdaterClient {
    get { self[UpdaterClient.self] }
    set { self[UpdaterClient.self] = newValue }
  }
}

extension UpdaterClient: EndpointOverridable {
  #if DEBUG
    public static let endpointDefault = URL(string: "http://127.0.0.1:8080/appcast.xml")!
  #else
    public static let endpointDefault = URL(string: "https://api.gertrude.app/appcast.xml")!
  #endif

  public static let endpointOverride = LockIsolated<URL?>(nil)
}

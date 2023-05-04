import Dependencies

public struct UpdaterClient: Sendable {
  public var triggerUpdate: @Sendable (String) async throws -> Void

  public init(triggerUpdate: @escaping @Sendable (String) async throws -> Void) {
    self.triggerUpdate = triggerUpdate
  }
}

extension UpdaterClient: TestDependencyKey {
  public static let testValue = Self(
    triggerUpdate: { _ in }
  )
}

public extension DependencyValues {
  var updater: UpdaterClient {
    get { self[UpdaterClient.self] }
    set { self[UpdaterClient.self] = newValue }
  }
}

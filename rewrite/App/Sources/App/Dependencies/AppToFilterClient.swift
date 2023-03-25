import Dependencies

struct AppToFilterClient: Sendable {
  var isConnectionHealthy: @Sendable () async -> Bool
}

extension AppToFilterClient: DependencyKey {
  static var liveValue: Self {
    .init(isConnectionHealthy: { true })
  }
}

extension AppToFilterClient: TestDependencyKey {
  static var testValue: Self {
    .init(isConnectionHealthy: { true })
  }
}

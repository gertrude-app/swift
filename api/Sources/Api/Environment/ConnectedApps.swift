import Gertie

struct ConnectedApps: Sendable {
  var add: @Sendable (AppConnection) async -> Void
  var remove: @Sendable (AppConnection) async -> Void
  var filterState: @Sendable (UserDevice.Id) async -> UserFilterState?
  var isUserDeviceOnline: @Sendable (UserDevice.Id) async -> Bool
  var notify: @Sendable (AppEvent) async throws -> Void
}

extension ConnectedApps {
  static var live: Self {
    let connections = AppConnections()
    Task { await connections.start() }
    return ConnectedApps(
      add: { await connections.add($0) },
      remove: { await connections.remove($0) },
      filterState: { await connections.filterState(for: $0) },
      isUserDeviceOnline: { await connections.isUserDeviceOnline($0) },
      notify: { try await connections.notify($0) }
    )
  }

  static var mock: Self {
    ConnectedApps(
      add: { _ in },
      remove: { _ in },
      filterState: { _ in nil },
      isUserDeviceOnline: { _ in false },
      notify: { _ in }
    )
  }
}

import Gertie

struct ConnectedApps: Sendable {
  var add: @Sendable (AppConnection) async -> Void
  var disconnectAll: @Sendable () async -> Void
  var remove: @Sendable (AppConnection) async -> Void
  var filterState: @Sendable (UserDevice.Id) async -> UserFilterState?
  var isUserDeviceOnline: @Sendable (UserDevice.Id) async -> Bool
  var notify: @Sendable (AppEvent) async throws -> Void
}

extension ConnectedApps {
  static var live: Self {
    Task { await AppConnections.shared.start() }
    return ConnectedApps(
      add: { await AppConnections.shared.add($0) },
      disconnectAll: { await AppConnections.shared.disconnectAll() },
      remove: { await AppConnections.shared.remove($0) },
      filterState: { await AppConnections.shared.filterState(for: $0) },
      isUserDeviceOnline: { await AppConnections.shared.isUserDeviceOnline($0) },
      notify: { try await AppConnections.shared.notify($0) }
    )
  }

  static var mock: Self {
    ConnectedApps(
      add: { _ in },
      disconnectAll: {},
      remove: { _ in },
      filterState: { _ in nil },
      isUserDeviceOnline: { _ in false },
      notify: { _ in }
    )
  }
}

import Shared

struct ConnectedApps {
  var add: (AppConnection) async -> Void
  var remove: (AppConnection) async -> Void
  var filterState: (Device.Id) async -> FilterState?
  var isDeviceOnline: (Device.Id) async -> Bool
  var notify: (AppEvent) async throws -> Void
}

extension ConnectedApps {
  static var live: Self {
    let connections = AppConnections()
    Task { await connections.start() }
    return ConnectedApps(
      add: { await connections.add($0) },
      remove: { await connections.remove($0) },
      filterState: { await connections.filterState(for: $0) },
      isDeviceOnline: { await connections.isDeviceOnline($0) },
      notify: { try await connections.notify($0) }
    )
  }

  static var mock: Self {
    ConnectedApps(
      add: { _ in },
      remove: { _ in },
      filterState: { _ in nil },
      isDeviceOnline: { _ in false },
      notify: { _ in }
    )
  }
}

import Dependencies
import Gertie

struct ConnectedApps: Sendable {
  var add: @Sendable (AppConnection) async -> Void
  var disconnectAll: @Sendable () async -> Void
  var remove: @Sendable (AppConnection) async -> Void
  var filterState: @Sendable (UserDevice.Id) async -> FilterState.WithoutTimes?
  var isUserDeviceOnline: @Sendable (UserDevice.Id) async -> Bool
  var sendEvent: @Sendable (AppEvent) async throws -> Void
}

extension ConnectedApps {
  func send(
    _ message: WebSocketMessage.FromApiToApp,
    to matcher: AppEvent.Matcher
  ) async throws {
    try await self.sendEvent(.init(matcher: matcher, message: message))
  }
}

// dependency

extension DependencyValues {
  var websockets: ConnectedApps {
    get { self[ConnectedApps.self] }
    set { self[ConnectedApps.self] = newValue }
  }
}

extension ConnectedApps: DependencyKey {
  public static var liveValue: ConnectedApps {
    Task { await AppConnections.shared.start() }
    return ConnectedApps(
      add: { await AppConnections.shared.add($0) },
      disconnectAll: { await AppConnections.shared.disconnectAll() },
      remove: { await AppConnections.shared.remove($0) },
      filterState: { await AppConnections.shared.filterState(for: $0) },
      isUserDeviceOnline: { await AppConnections.shared.isUserDeviceOnline($0) },
      sendEvent: { try await AppConnections.shared.send($0) }
    )
  }
}

#if DEBUG
  extension ConnectedApps: TestDependencyKey {
    public static var testValue: ConnectedApps {
      ConnectedApps(
        add: unimplemented("ConnectedApps.add()"),
        disconnectAll: unimplemented("ConnectedApps.disconnectAll()"),
        remove: unimplemented("ConnectedApps.remove()"),
        filterState: unimplemented("ConnectedApps.filterState()", placeholder: nil),
        isUserDeviceOnline: unimplemented("ConnectedApps.isUserDeviceOnline()", placeholder: false),
        sendEvent: unimplemented("ConnectedApps.sendEvent()")
      )
    }
  }
#endif

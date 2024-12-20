import Dependencies
import Foundation
import Gertie

@globalActor actor AppConnections {
  static let shared = AppConnections()

  let id = UUID()
  var connections: [AppConnection.Id: AppConnection] = [:]

  @Dependency(\.logger) private var logger

  func start() async {
    while true {
      try? await Task.sleep(seconds: 120)
      self.flush()
    }
  }

  func add(_ newConnection: AppConnection) {
    let numDupes = self.connections.values.filter { existing in
      existing.ids.userDevice == newConnection.ids.userDevice
    }.count
    if numDupes > 0 {
      self.logger.error("AppConnections: opening duplicate connection (ws)")
      self.logger.error("  -> \(numDupes) connection/s already existed (ws)")
      self.logger.error("  -> matching user device id: \(newConnection.ids.userDevice) (ws)")
    } else {
      self.logger.notice("AppConnections: opening new connection (ws)")
      self.logger.notice("  -> for user device id: \(newConnection.ids.userDevice) (ws)")
    }
    self.connections[newConnection.id] = newConnection
  }

  func remove(_ connection: AppConnection) {
    self.connections.removeValue(forKey: connection.id)
  }

  func disconnectAll() async {
    self.logger.notice("AppConnections: disconnecting all (ws)")
    for connection in self.connections.values {
      try? await connection.ws.close(code: .goingAway)
      self.remove(connection)
    }
  }

  func filterState(for userDeviceId: UserDevice.Id) async -> FilterState.WithoutTimes? {
    for connection in self.connections.values {
      if connection.ids.userDevice == userDeviceId {
        return await connection.filterState
      }
    }
    return nil
  }

  func isUserDeviceOnline(_ id: UserDevice.Id) -> Bool {
    self.connections.values.contains { $0.ids.userDevice == id }
  }

  private func flush() {
    self.logger.notice("AppConnections: flushing closed connections (ws)")
    self.logger.notice("  -> self.id: \(self.id.lowercased) (ws)")
    self.connections.values.filter(\.ws.isClosed).forEach { connection in
      self.logger.notice("  -> removing connection: \(connection.id) (ws)")
      self.logger.notice("  -> for user device id: \(connection.ids.userDevice) (ws)")
      self.remove(connection)
    }
  }

  private var currentConnections: [AppConnection] {
    self.flush()
    return Array(self.connections.values)
  }

  func send(_ event: AppEvent) async throws {
    try await self.currentConnections
      .filter { $0.ids.satisfies(matcher: event.matcher) }
      .asyncForEach { @Sendable conn in
        try await conn.ws.send(app: event.message)
      }
  }

  deinit {
    connections.values.forEach { _ = $0.ws.close(code: .goingAway) }
    connections = [:]
  }
}

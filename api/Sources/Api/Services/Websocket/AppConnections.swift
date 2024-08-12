import Foundation
import Gertie

private typealias OutgoingMessage = WebSocketMessage.FromApiToApp

@globalActor actor AppConnections {
  static let shared = AppConnections()

  let id = UUID()
  var connections: [AppConnection.Id: AppConnection] = [:]

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
      Current.logger.error("AppConnections: opening duplicate connection (ws)")
      Current.logger.error("  -> \(numDupes) connection/s already existed (ws)")
      Current.logger.error("  -> matching user device id: \(newConnection.ids.userDevice) (ws)")
    } else {
      Current.logger.notice("AppConnections: opening new connection (ws)")
      Current.logger.notice("  -> for user device id: \(newConnection.ids.userDevice) (ws)")
    }
    self.connections[newConnection.id] = newConnection
  }

  func remove(_ connection: AppConnection) {
    self.connections.removeValue(forKey: connection.id)
  }

  func disconnectAll() async {
    Current.logger.notice("AppConnections: disconnecting all (ws)")
    for connection in self.connections.values {
      try? await connection.ws.close(code: .goingAway)
      self.remove(connection)
    }
  }

  func filterState(for userDeviceId: UserDevice.Id) async -> UserFilterState? {
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
    Current.logger.notice("AppConnections: flushing closed connections (ws)")
    Current.logger.notice("  -> self.id: \(self.id.lowercased) (ws)")
    self.connections.values.filter(\.ws.isClosed).forEach { connection in
      Current.logger.notice("  -> removing connection: \(connection.id) (ws)")
      Current.logger.notice("  -> for user device id: \(connection.ids.userDevice) (ws)")
      self.remove(connection)
    }
  }

  private var currentConnections: [AppConnection] {
    self.flush()
    return Array(self.connections.values)
  }

  func notify(_ event: AppEvent) async throws {
    switch event {
    case .keychainUpdated(let keychainId):
      try await self.currentConnections
        .filter { $0.ids.keychains.contains(keychainId) }
        .asyncForEach { @Sendable conn in
          try await conn.ws.send(codable: OutgoingMessage.userUpdated)
        }

    case .userUpdated(let userId):
      try await self.currentConnections
        .filter { $0.ids.user == userId }
        .asyncForEach { @Sendable conn in
          try await conn.ws.send(codable: OutgoingMessage.userUpdated)
        }

    case .userDeleted(let userId):
      try await self.currentConnections
        .filter { $0.ids.user == userId }
        .asyncForEach { @Sendable conn in
          try await conn.ws.send(codable: OutgoingMessage.userDeleted)
        }

    case .unlockRequestUpdated(let payload):
      try await self.currentConnections
        .filter { $0.ids.userDevice == payload.userDeviceId }
        .asyncForEach { @Sendable conn in
          try await conn.ws.send(
            codable:
            OutgoingMessage.unlockRequestUpdated(
              status: payload.status,
              target: payload.target,
              parentComment: payload.responseComment
            )
          )
        }

    case .suspendFilterRequestDecided(let userDeviceId, let decision, let comment):
      try await self.currentConnections
        .filter { $0.ids.userDevice == userDeviceId }
        .asyncForEach { @Sendable conn in
          try await conn.ws.send(
            codable:
            OutgoingMessage.filterSuspensionRequestDecided(decision: decision, comment: comment)
          )
        }

    case .suspendFilterRequestUpdated(let payload):
      if payload.status == .accepted {
        try await self.currentConnections
          .filter { $0.ids.userDevice == payload.userDeviceId }
          .asyncForEach { @Sendable conn in
            try await conn.ws.send(
              codable:
              OutgoingMessage.suspendFilter(
                for: payload.duration,
                parentComment: payload.responseComment
              )
            )
          }
      } else {
        try await self.currentConnections
          .filter { $0.ids.userDevice == payload.userDeviceId }
          .asyncForEach { @Sendable conn in
            try await conn.ws.send(
              codable:
              OutgoingMessage.suspendFilterRequestDenied(
                parentComment: payload.responseComment
              )
            )
          }
      }
    }
  }

  deinit {
    connections.values.forEach { _ = $0.ws.close(code: .goingAway) }
    connections = [:]
  }
}

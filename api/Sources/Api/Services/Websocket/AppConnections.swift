import Gertie

actor AppConnections {
  typealias OutgoingMessage = WebSocketMessage.FromApiToApp
  var connections: [AppConnection.Id: AppConnection] = [:]

  func start() async {
    while true {
      try? await Task.sleep(seconds: 120)
      flush()
    }
  }

  func add(_ connection: AppConnection) {
    connections[connection.id] = connection
  }

  func remove(_ connection: AppConnection) {
    connections.removeValue(forKey: connection.id)
  }

  func filterState(for deviceId: Device.Id) -> UserFilterState? {
    for connection in connections.values {
      if connection.ids.device == deviceId {
        return connection.filterState
      }
    }
    return nil
  }

  func isDeviceOnline(_ id: Device.Id) -> Bool {
    connections.values.contains { $0.ids.device == id }
  }

  private func flush() {
    connections.values.filter(\.ws.isClosed).forEach {
      self.remove($0)
    }
  }

  private var currentConnections: [AppConnection] {
    flush()
    return Array(connections.values)
  }

  func notify(_ event: AppEvent) async throws {
    switch event {
    case .keychainUpdated(let keychainId):
      try await currentConnections
        .filter { $0.ids.keychains.contains(keychainId) }
        .asyncForEach {
          try await $0.ws.send(codable: OutgoingMessage.userUpdated)
        }

    case .userUpdated(let userId):
      try await currentConnections
        .filter { $0.ids.user == userId }
        .asyncForEach {
          try await $0.ws.send(codable: OutgoingMessage.userUpdated)
        }

    case .unlockRequestUpdated(let payload):
      try await currentConnections
        .filter { $0.ids.device == payload.deviceId }
        .asyncForEach {
          try await $0.ws.send(
            codable:
            OutgoingMessage.unlockRequestUpdated(
              status: payload.status,
              target: payload.target,
              parentComment: payload.responseComment
            )
          )
        }

    case .suspendFilterRequestUpdated(let payload):
      if payload.status == .accepted {
        try await currentConnections
          .filter { $0.ids.device == payload.deviceId }
          .asyncForEach {
            try await $0.ws.send(
              codable:
              OutgoingMessage.suspendFilter(
                for: payload.duration,
                parentComment: payload.responseComment
              )
            )
          }
      } else {
        try await currentConnections
          .filter { $0.ids.device == payload.deviceId }
          .asyncForEach {
            try await $0.ws.send(
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

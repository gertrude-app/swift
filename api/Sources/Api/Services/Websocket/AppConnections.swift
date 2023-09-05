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

  func filterState(for userDeviceId: UserDevice.Id) -> UserFilterState? {
    for connection in connections.values {
      if connection.ids.userDevice == userDeviceId {
        return connection.filterState
      }
    }
    return nil
  }

  func isUserDeviceOnline(_ id: UserDevice.Id) -> Bool {
    connections.values.contains { $0.ids.userDevice == id }
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

    case .userDeleted(let userId):
      try await currentConnections
        .filter { $0.ids.user == userId }
        .asyncForEach {
          try await $0.ws.send(codable: OutgoingMessage.userDeleted)
        }

    case .unlockRequestUpdated(let payload):
      try await currentConnections
        .filter { $0.ids.userDevice == payload.userDeviceId }
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

    case .suspendFilterRequestDecided(let userDeviceId, let decision):
      try await currentConnections
        .filter { $0.ids.userDevice == userDeviceId }
        .asyncForEach {
          try await $0.ws.send(codable: OutgoingMessage.filterSuspensionRequestDecided(decision))
        }

    case .suspendFilterRequestUpdated(let payload):
      if payload.status == .accepted {
        try await currentConnections
          .filter { $0.ids.userDevice == payload.userDeviceId }
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
          .filter { $0.ids.userDevice == payload.userDeviceId }
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

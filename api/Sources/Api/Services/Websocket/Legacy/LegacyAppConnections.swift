import Gertie

actor LegacyAppConnections {
  typealias OutgoingMessage = WebsocketMsg.ApiToApp.Message
  var connections: [LegacyAppConnection.Id: LegacyAppConnection] = [:]

  func start() async {
    while true {
      try? await Task.sleep(seconds: 120)
      flush()
    }
  }

  func add(_ connection: LegacyAppConnection) {
    connections[connection.id] = connection
  }

  func remove(_ connection: LegacyAppConnection) {
    connections.removeValue(forKey: connection.id)
  }

  func filterState(for userDeviceId: UserDevice.Id) -> FilterState? {
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

  private var currentConnections: [LegacyAppConnection] {
    flush()
    return Array(connections.values)
  }

  func notify(_ event: AppEvent) async throws {
    switch event {
    case .keychainUpdated(let keychainId):
      try await currentConnections
        .filter { $0.ids.keychains.contains(keychainId) }
        .asyncForEach {
          try await $0.ws.send(codable: OutgoingMessage(type: .userUpdated))
        }

    case .userUpdated(let userId):
      try await currentConnections
        .filter { $0.ids.user == userId }
        .asyncForEach {
          try await $0.ws.send(codable: OutgoingMessage(type: .userUpdated))
        }

    case .userDeleted:
      break // not handled by legacy app

    case .unlockRequestUpdated(let payload):
      try await currentConnections
        .filter { $0.ids.userDevice == payload.userDeviceId }
        .asyncForEach {
          try await $0.ws.send(
            codable:
            OutgoingMessage.UnlockRequestUpdated(
              status: payload.status,
              target: payload.target,
              comment: payload.comment,
              responseComment: payload.responseComment
            )
          )
        }

    case .suspendFilterRequestUpdated(let payload):
      if payload.status == .accepted {
        try await currentConnections
          .filter { $0.ids.userDevice == payload.userDeviceId }
          .asyncForEach {
            try await $0.ws.send(
              codable:
              OutgoingMessage.SuspendFilter(
                suspension: .init(scope: .unrestricted, duration: payload.duration),
                comment: payload.responseComment
              )
            )
          }
      } else {
        try await currentConnections
          .filter { $0.ids.userDevice == payload.userDeviceId }
          .asyncForEach {
            try await $0.ws.send(
              codable:
              OutgoingMessage.SuspendFilterRequestDenied(
                requestComment: payload.requestComment,
                responseComment: payload.responseComment
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

import Shared

actor AppConnections {
  typealias OutgoingMessage = WebsocketMsg.ApiToApp.Message
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

  func filterState(for deviceId: Device.Id) -> FilterState? {
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

  func notify(_ event: AppEvent) {
    switch event {
    case .keychainUpdated(let keychainId):
      currentConnections
        .filter { $0.ids.keychains.contains(keychainId) }
        .forEach {
          try? $0.ws.send(OutgoingMessage(type: .userUpdated))
        }

    case .userUpdated(let userId):
      currentConnections
        .filter { $0.ids.user == userId }
        .forEach {
          try? $0.ws.send(OutgoingMessage(type: .userUpdated))
        }

    case .unlockRequestUpdated(let payload):
      currentConnections
        .filter { $0.ids.device == payload.deviceId }
        .forEach {
          try? $0.ws.send(
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
        currentConnections
          .filter { $0.ids.device == payload.deviceId }
          .forEach {
            try? $0.ws.send(
              OutgoingMessage.SuspendFilter(
                suspension: .init(scope: .unrestricted, duration: payload.duration),
                comment: payload.responseComment
              )
            )
          }
      } else {
        currentConnections
          .filter { $0.ids.device == payload.deviceId }
          .forEach {
            try? $0.ws.send(
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

import Duet
import Shared
import Vapor

final class AppConnections: LifecycleHandler {
  private typealias OutgoingMessage = WebsocketMsg.ApiToApp.Message
  static let shared = AppConnections()
  private var timer: Timer?

  private init() {
    timer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
      self?.flush()
    }
  }

  @ThreadSafe var connections: [AppConnection.Id: AppConnection] = [:]

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

  func deviceOnline(_ id: Device.Id) -> Bool {
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

  func notify(_ event: Event) {
    switch event {
    case .keychainUpdated(let payload):
      currentConnections
        .filter { $0.ids.keychains.contains(payload.keychainId) }
        .forEach {
          try? $0.ws.send(OutgoingMessage(type: .userUpdated))
        }

    case .userUpdated(let payload):
      currentConnections
        .filter { $0.ids.user == payload.userId }
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
                suspension: .init(scope: payload.scope, duration: payload.duration),
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

    default:
      break
    }
  }

  func shutdown(_ application: Application) {
    connections.values.forEach { _ = $0.ws.close(code: .goingAway) }
    connections = [:]
  }
}

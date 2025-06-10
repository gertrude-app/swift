import Dependencies
import Foundation
import Gertie

@globalActor actor AppConnections {
  static let shared = AppConnections()

  var connections: [AppConnection.Id: AppConnection] = [:]

  @Dependency(\.logger) private var logger

  func start() async {
    while true {
      try? await Task.sleep(seconds: 120)
      self.flush()
    }
  }

  func add(_ connection: AppConnection) {
    let dupes: [AppConnection] = self.connections.values.filter {
      $0.ids.computerUser == connection.ids.computerUser
    }
    if dupes.count > 0 {
      connection.log("ERR! open dupe", extra: "dupes: \(dupes.count)")
      dupes.forEach { self.remove($0) }
    } else {
      connection.log("opened")
    }
    self.connections[connection.id] = connection
  }

  func remove(_ connection: AppConnection) {
    connection.log("being removed")
    self.connections.removeValue(forKey: connection.id)
  }

  func disconnectAll() async {
    self.logger.notice("AppConnections: disconnecting all (ws)")
    for connection in self.connections.values {
      try? await connection.ws.close(code: .goingAway)
      self.remove(connection)
    }
  }

  func status(for computerId: ComputerUser.Id) async -> ChildComputerStatus {
    for connection in self.connections.values {
      if connection.ids.computerUser == computerId {
        let state = connection.filterState.withLock { $0 }
        switch state {
        case .withoutTimes(let filterState):
          return filterState.status
        case .withTimes(let filterState):
          return filterState.status
        case nil:
          return .offline
        }
      }
    }
    return .offline
  }

  private func flush() {
    for connection in self.connections.values.filter(\.isDead) {
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

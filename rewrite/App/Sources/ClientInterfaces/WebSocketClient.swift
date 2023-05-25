import Combine
import Dependencies
import Foundation
import Gertie
import TaggedTime

public struct WebSocketClient: Sendable {
  public typealias Message = WebSocketMessage

  public enum State: Equatable, Sendable {
    case notConnected
    case connecting
    case connected
  }

  public var connect: @Sendable (UUID, URL?) async throws -> State
  public var disconnect: @Sendable () async throws -> Void
  public var receive: @Sendable () -> AnyPublisher<Message.FromApiToApp, Never>
  public var send: @Sendable (Message.FromAppToApi) async throws -> Void
  public var state: @Sendable () async throws -> State

  public init(
    connect: @escaping @Sendable (UUID, URL?) async throws -> State,
    disconnect: @escaping @Sendable () async throws -> Void,
    receive: @escaping @Sendable () -> AnyPublisher<WebSocketClient.Message.FromApiToApp, Never>,
    send: @escaping @Sendable (WebSocketClient.Message.FromAppToApi) async throws -> Void,
    state: @escaping @Sendable () async throws -> State
  ) {
    self.connect = connect
    self.disconnect = disconnect
    self.receive = receive
    self.send = send
    self.state = state
  }
}

extension WebSocketClient: TestDependencyKey {
  public static let testValue = Self(
    connect: { _, _ in .connected },
    disconnect: {},
    receive: { Empty().eraseToAnyPublisher() },
    send: { _ in },
    state: { .connected }
  )
}

public extension DependencyValues {
  var websocket: WebSocketClient {
    get { self[WebSocketClient.self] }
    set { self[WebSocketClient.self] = newValue }
  }
}

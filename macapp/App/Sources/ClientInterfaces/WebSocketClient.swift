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

  public var connect: @Sendable (UUID) async throws -> State
  public var disconnect: @Sendable () async throws -> Void
  public var receive: @Sendable () -> AnyPublisher<Message.FromApiToApp, Never>
  public var send: @Sendable (Message.FromAppToApi) async throws -> Void
  public var state: @Sendable () async throws -> State

  public init(
    connect: @escaping @Sendable (UUID) async throws -> State,
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

extension WebSocketClient: EndpointOverridable {
  #if DEBUG
    public static let endpointDefault = URL(string: "http://127.0.0.1:8080/app-websocket")!
  #else
    public static let endpointDefault = URL(string: "https://api.gertrude.app/app-websocket")!
  #endif

  public static let endpointOverride = LockIsolated<URL?>(nil)
}

extension WebSocketClient: TestDependencyKey {
  public static let testValue = Self(
    connect: unimplemented("WebSocketClient.connect"),
    disconnect: unimplemented("WebSocketClient.disconnect"),
    receive: unimplemented("WebSocketClient.receive"),
    send: unimplemented("WebSocketClient.send"),
    state: unimplemented("WebSocketClient.state")
  )

  public static let mock = Self(
    connect: { _ in .connected },
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

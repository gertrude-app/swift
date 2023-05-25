import Combine
import CombineSchedulers
import Core
import Gertie
import Starscream
import XCore
import XCTest
import XExpect

@testable import LiveWebSocketClient

final class WebsocketTests: XCTestCase {
  var scheduler = DispatchQueue.test
  var socket = TestSocket()
  var conn: LiveWebSocketClient.WebSocketConnection!
  var receivedMessages: [WebSocketMessage.FromApiToApp] = []
  var cancellables: Set<AnyCancellable> = []

  var state: LiveWebSocketClient.ConnectionState { conn.currentState }
  var ws: WebSocket { WebSocket(request: .init(url: URL(string: "/")!)) }

  override func setUp() {
    receivedMessages = []

    let subject = PassthroughSubject<WebSocketMessage.FromApiToApp, Never>()
    subject.eraseToAnyPublisher().sink { [self] in
      self.receivedMessages.append($0)
    }.store(in: &cancellables)

    scheduler = DispatchQueue.test
    conn = WebSocketConnection(
      scheduler: scheduler.eraseToAnyScheduler(),
      messageSubject: Mutex(subject)
    ) { [self] in
      self.socket = TestSocket()
      return self.socket
    }
  }

  func send(_ event: WebSocketEvent) {
    conn.didReceive(event: event, client: ws)
  }

  func testConnection() throws {
    expect(state).toEqual(.idle)
    expect(socket.connectCalls).toEqual(1)

    send(.connected([:]))
    expect(state).toEqual(.connected)

    send(.disconnected("some reason", 1))
    expect(state).toEqual(.disconnected)
  }

  func testDisconnect() {
    send(.connected([:]))
    expect(state).toEqual(.connected)

    send(.disconnected("some reason", 1))
    expect(state).toEqual(.disconnected)

    // never tries to reconnect on its own (app heartbeat responsible)
    scheduler.advance(by: 1000)
    expect(state).toEqual(.disconnected)
  }

  func testPingPong() {
    send(.connected([:]))

    scheduler.advance(by: conn.pingInterval - 1)
    expect(state).toEqual(.connected)

    scheduler.advance(by: 1)
    expect(state).toEqual(.waitingForPong)

    send(.pong(nil))
    expect(state).toEqual(.connected)

    scheduler.advance(by: PONG_CONFIRMATION_DELAY + conn.pingInterval - 1)
    expect(state).toEqual(.connected)

    scheduler.advance(by: 1)
    expect(state).toEqual(.waitingForPong)

    send(.pong(nil))
    expect(state).toEqual(.connected)
  }

  func testFailedToReceivePongReestablishesConnection() {
    send(.connected([:]))

    scheduler.advance(by: conn.pingInterval - 1)
    expect(conn.pingsSent).toEqual(0)
    expect(state).toEqual(.connected)

    scheduler.advance(by: 1)
    expect(state).toEqual(.waitingForPong)
    expect(conn.pingsSent).toEqual(1)

    scheduler.advance(by: 5) // should have receive pong by now!
    expect(state).toEqual(.disconnected)
  }

  // test that it passes messages on
  func testPassesMessagesOnToHandler() throws {
    send(.connected([:]))

    let message = WebSocketMessage.FromApiToApp.currentFilterStateRequested
    let json = try JSON.encode(message)
    send(.text(json))

    expect(receivedMessages).toEqual([.currentFilterStateRequested])
  }

  func testReceivingCancelledReschedulesConnectionIn30Seconds() {
    send(.connected([:]))

    send(.cancelled)
    expect(state).toEqual(.disconnected)

    // never tries to reconnect on its own (app heartbeat responsible)
    scheduler.advance(by: 1000)
    expect(state).toEqual(.disconnected)
  }

  func testDirectDisconnect() {
    send(.connected([:]))
    expect(state).toEqual(.connected)

    conn.disconnect()
    expect(state).toEqual(.disconnected)
    expect(socket.disconnectCalls).toEqual(1)
  }
}

// helpers

class TestSocket: WebSocketClient {
  var connectCalls = 0
  var disconnectCalls = 0

  func connect() {
    connectCalls += 1
  }

  func disconnect(closeCode: UInt16) {
    disconnectCalls += 1
  }

  func write(string: String, completion: (() -> Void)?) {}
  func write(stringData: Data, completion: (() -> Void)?) {}
  func write(data: Data, completion: (() -> Void)?) {}
  func write(ping: Data, completion: (() -> Void)?) {}
  func write(pong: Data, completion: (() -> Void)?) {}
}

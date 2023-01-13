import CombineSchedulers
import Shared
import Starscream
import XCTest

@testable import Websocket

final class WebsocketTests: XCTestCase {
  var scheduler = DispatchQueue.test
  var socket = TestSocket()
  var conn: WebsocketConnection!
  var receivedMessages: [String] = []

  var state: Websocket.ConnectionState.State { conn.state.get }
  var ws: WebSocket { WebSocket(request: .init(url: URL(string: "/")!)) }

  override func setUp() {
    scheduler = DispatchQueue.test
    conn = WebsocketConnection(
      scheduler: scheduler.eraseToAnyScheduler(),
      handleIncomingMessage: { [self] in self.receivedMessages.append($0) }
    ) { [self] in
      self.socket = TestSocket()
      return self.socket
    }
  }

  func send(_ event: WebSocketEvent) {
    conn.didReceive(event: event, client: ws)
  }

  func testConnection() throws {
    XCTAssertEqual(state, .waitingForConnection)
    XCTAssertEqual(socket.connectCalls, 1)

    send(.connected([:]))
    XCTAssertEqual(state, .connected)

    send(.disconnected("some reason", 1))
    XCTAssertEqual(state, .disconnected)
  }

  func testAfterDisconnectAttemptsToReconnectIn3Minutes() {
    send(.connected([:]))
    send(.disconnected("some reason", 1))

    scheduler.advance(by: 179)
    XCTAssertEqual(state, .disconnected)

    scheduler.advance(by: 1)
    XCTAssertEqual(state, .waitingForConnection)

    send(.connected([:]))
    XCTAssertEqual(state, .connected)
  }

  func testWaitsLongerToReconnectIfDisconnectReasonIsMissingUserToken() {
    send(.connected([:]))
    send(.disconnected("", WebsocketMsg.Error.USER_TOKEN_NOT_FOUND))

    scheduler.advance(by: 60 * 60 - 1)
    XCTAssertEqual(state, .disconnected)

    scheduler.advance(by: 1)
    XCTAssertEqual(state, .waitingForConnection)

    send(.connected([:]))
    XCTAssertEqual(state, .connected)
  }

  func testHeartbeatHappyPath() {
    send(.connected([:]))

    scheduler.advance(by: conn.heartbeatInterval - 1)
    XCTAssertEqual(state, .connected)

    scheduler.advance(by: 1)
    XCTAssertEqual(state, .waitingForPong)

    send(.pong(nil))
    XCTAssertEqual(state, .connected)

    scheduler.advance(by: PONG_CONFIRMATION_DELAY + conn.heartbeatInterval - 1)
    XCTAssertEqual(state, .connected)

    scheduler.advance(by: 1)
    XCTAssertEqual(state, .waitingForPong)

    send(.pong(nil))
    XCTAssertEqual(state, .connected)
  }

  func testFailedToReceivePongReestablishesConnection() {
    send(.connected([:]))

    scheduler.advance(by: conn.heartbeatInterval - 1)
    XCTAssertEqual(conn.heartbeats, 0)
    XCTAssertEqual(state, .connected)

    scheduler.advance(by: 1)
    XCTAssertEqual(state, .waitingForPong)
    XCTAssertEqual(conn.heartbeats, 1)

    scheduler.advance(by: 5) // should have receive pong by now!
    XCTAssertEqual(state, .waitingForConnection)

    // simulate that we are now reconnected
    send(.connected([:]))
    XCTAssertEqual(state, .connected)

    scheduler.advance(by: conn.heartbeatInterval - 1)
    // make sure we don't have old heartbeat timers lying around
    XCTAssertEqual(conn.heartbeats, 1)
    XCTAssertEqual(state, .connected)

    scheduler.advance(by: 1)
    XCTAssertEqual(state, .waitingForPong)
    XCTAssertEqual(conn.heartbeats, 2)
  }

  // test that it passes messages on
  func testPassesMessagesOnToHandler() {
    send(.connected([:]))

    let message = IncomingMessage.RequestCurrentFilterState()
    send(.text(message.json!))

    XCTAssertEqual(receivedMessages, [message.json])
  }

  func testReceivingCancelledReschedulesConnectionIn30Seconds() {
    send(.connected([:]))

    send(.cancelled)
    XCTAssertEqual(state, .disconnected)

    scheduler.advance(by: 29)
    XCTAssertEqual(state, .disconnected)

    scheduler.advance(by: 1)
    XCTAssertEqual(state, .waitingForConnection)

    send(.connected([:]))
    XCTAssertEqual(state, .connected)
  }

  func testDisconnect() {
    send(.connected([:]))
    XCTAssertEqual(state, .connected)

    conn.disconnect()
    XCTAssertEqual(state, .disconnected)
    XCTAssertEqual(socket.disconnectCalls, 1)
  }

  func testReconnect() {
    send(.connected([:]))
    XCTAssertEqual(state, .connected)

    conn.reconnect()
    XCTAssertEqual(state, .disconnected)
    XCTAssertEqual(socket.disconnectCalls, 1)

    scheduler.advance(by: 5)
    XCTAssertEqual(state, .waitingForConnection)

    send(.connected([:]))
    XCTAssertEqual(state, .connected)
  }
}

class TestSocket: WebSocketClient {
  var connectCalls = 0
  func connect() {
    connectCalls += 1
  }

  var disconnectCalls = 0
  func disconnect(closeCode: UInt16) {
    disconnectCalls += 1
  }

  func write(string: String, completion: (() -> Void)?) {}
  func write(stringData: Data, completion: (() -> Void)?) {}
  func write(data: Data, completion: (() -> Void)?) {}
  func write(ping: Data, completion: (() -> Void)?) {}
  func write(pong: Data, completion: (() -> Void)?) {}
}

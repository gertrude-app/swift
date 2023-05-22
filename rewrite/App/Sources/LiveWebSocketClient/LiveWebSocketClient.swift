import Combine
import Core
import Dependencies
import Foundation
import Models
import Shared
import Starscream

extension Models.WebSocketClient: DependencyKey {
  public static var liveValue: Self {
    @Dependency(\.mainQueue) var mainQueue

    @Sendable func tearDownCurrentConnection() async {
      let priorExisted = connection.withValue { current in
        guard let current else { return false }
        current.disconnect()
        return true
      }

      // not sure if necessary, but give a little time for disconnect
      if priorExisted {
        try? await mainQueue.sleep(for: .milliseconds(500))
        connection.replace(with: nil)
      }
    }

    @Sendable func currentState() -> State {
      connection.withValue { current in
        guard let current else { return .notConnected }
        return current.clientState()
      }
    }

    return Self(
      connect: { token, customUrl in
        await tearDownCurrentConnection()
        let newConnection =
          WebSocketConnection(
            log: {
              #if DEBUG
                print("• WebSocketConnection log: \($0)\n")
              #endif
            },
            logError: {
              #if DEBUG
                print("• WebSocketConnection error: \($0)\n")
              #endif
            },
            messageSubject: messageSubject
          ) { [token, customUrl] in
            var request = URLRequest(url: customUrl ?? WS_URL)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            return WebSocket(request: request)
          }
        connection.replace(with: newConnection)

        // seems to take a bit of time for connection to be fully established
        // delay a bit so that when we return from this function, we know
        // we can immediately start sending messages
        try? await mainQueue.sleep(for: .seconds(1))

        let state = currentState()
        guard state != .connecting else { return state }
        try? await mainQueue.sleep(for: .milliseconds(500))
        return currentState()
      },

      disconnect: {
        await tearDownCurrentConnection()
      },

      receive: {
        messageSubject.withValue { subject in
          Move(subject.eraseToAnyPublisher())
        }.consume()
      },

      send: { message in
        try connection.withValue { current in
          guard let current else { throw Error.noConnectionForSend }
          current.send(message)
        }
      },

      state: {
        currentState()
      }
    )
  }

  enum Error: Swift.Error { case noConnectionForSend }
}

private let connection = Mutex<WebSocketConnection?>(nil)
private let messageSubject = Mutex(PassthroughSubject<WebSocketMessage.FromApiToApp, Never>())

#if DEBUG
  internal let WS_URL = URL(string: "http://127.0.0.1:8080/app-websocket")!
#else
  internal let WS_URL = URL(string: "https://api.gertrude.app/app-websocket")!
#endif

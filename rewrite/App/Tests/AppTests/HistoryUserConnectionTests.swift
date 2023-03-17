import ComposableArchitecture
import XCTest

@testable import App
@testable import Models

@MainActor final class HistoryUserConnectionTests: XCTestCase {
  func testHistoryUserConnectionHappyPath() async {
    let store = TestStore(
      initialState: History.UserConnection.State.notConnected,
      reducer: History.UserConnection()
    )
    store.dependencies.api.connectUser = { _ in .mock }

    await store.send(.connectClicked) {
      $0 = .enteringConnectionCode
    }

    await store.send(.connectSubmitted(code: 111_222)) {
      $0 = .connecting
    }

    await store.receive(.connectResponse(.success(.mock))) {
      $0 = .established(welcomeDismissed: false)
    }

    await store.send(.welcomeDismissed) {
      $0 = .established(welcomeDismissed: true)
    }
  }

  func testHistoryUserConnectionError() async {
    let store = TestStore(
      initialState: History.UserConnection.State.enteringConnectionCode,
      reducer: History.UserConnection()
    )
    store.dependencies.api.connectUser = { _ in throw TestErr("Oh no!") }

    await store.send(.connectSubmitted(code: 111_222)) {
      $0 = .connecting
    }

    await store.receive(.connectResponse(.failure(TestErr("Oh no!")))) {
      $0 = .connectFailed("Oh no!")
    }

    await store.send(.retryConnectClicked) {
      $0 = .enteringConnectionCode
    }
  }
}

struct TestErr: Equatable, Error, LocalizedError {
  let msg: String
  var errorDescription: String? { msg }
  init(_ msg: String) { self.msg = msg }
}

extension User {
  static let mock = User(
    id: .init(uuidString: "00000000-0000-0000-0000-000000000000")!,
    token: .init(uuidString: "00000000-0000-0000-0000-000000000000")!,
    deviceId: .init(uuidString: "00000000-0000-0000-0000-000000000000")!,
    name: "Huck",
    keyloggingEnabled: true,
    screenshotsEnabled: true,
    screenshotFrequency: 1,
    screenshotSize: 1,
    connectedAt: .init(timeIntervalSince1970: 0)
  )
}

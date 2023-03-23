import ComposableArchitecture
import XCTest
import XExpect

@testable import App
@testable import Models

@MainActor final class HistoryUserConnectionTests: XCTestCase {
  func testHistoryUserConnectionHappyPath() async {
    let store = TestStore(initialState: AppReducer.State(), reducer: AppReducer())
    store.dependencies.api.connectUser = { _ in .mock }
    let savedState = LockIsolated<Persistent.State?>(nil)
    store.dependencies.storage.savePersistentState = { state in
      savedState.setValue(state)
    }

    await store.send(.menuBar(.connectClicked)) {
      $0.history.userConnection = .enteringConnectionCode
    }

    await store.send(.menuBar(.connectSubmit(code: 111_222))) {
      $0.history.userConnection = .connecting
    }

    await store.receive(.history(.userConnection(.connect(.success(.mock))))) {
      $0.user = .mock
      $0.history.userConnection = .established(welcomeDismissed: false)
    }

    expect(savedState.value).toEqual(.init(user: .mock))

    await store.send(.menuBar(.welcomeAdminClicked)) {
      $0.history.userConnection = .established(welcomeDismissed: true)
    }
  }

  func testHistoryUserConnectionError() async {
    let store = TestStore(initialState: AppReducer.State(), reducer: AppReducer())
    store.dependencies.api.connectUser = { _ in throw TestErr("Oh no!") }

    await store.send(.menuBar(.connectClicked)) {
      $0.history.userConnection = .enteringConnectionCode
    }

    await store.send(.menuBar(.connectSubmit(code: 111_222))) {
      $0.history.userConnection = .connecting
    }

    await store.receive(.history(.userConnection(.connect(.failure(TestErr("Oh no!")))))) {
      $0.history.userConnection = .connectFailed("Oh no!")
    }

    await store.send(.menuBar(.retryConnectClicked)) {
      $0.history.userConnection = .enteringConnectionCode
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

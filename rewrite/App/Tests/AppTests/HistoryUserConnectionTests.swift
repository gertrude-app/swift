import ComposableArchitecture
import Models
import XCTest
import XExpect

@testable import App

@MainActor final class HistoryUserConnectionTests: XCTestCase {
  func testHistoryUserConnectionHappyPath() async {
    let store = TestStore(initialState: AppReducer.State(), reducer: AppReducer())
    store.dependencies.api.connectUser = { _ in .mock }

    let savedState = LockIsolated<Persistent.State?>(nil)
    store.dependencies.storage.savePersistentState = { state in
      savedState.setValue(state)
    }

    let apiUserToken = ActorIsolated<User.Token?>(nil)
    store.deps.api.setUserToken = { await apiUserToken.setValue($0) }

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

    expect(savedState).toEqual(.init(user: .mock))
    await expect(apiUserToken).toEqual(User.mock.token)

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

import ComposableArchitecture
import TestSupport
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

    let apiUserToken = ActorIsolated<UUID?>(nil)
    store.deps.api.setUserToken = { await apiUserToken.setValue($0) }

    await store.send(.menuBar(.connectClicked)) {
      $0.history.userConnection = .enteringConnectionCode
    }

    await store.send(.menuBar(.connectSubmit(code: 111_222))) {
      $0.history.userConnection = .connecting
    }

    await store.receive(.history(.userConnection(.connect(.success(.mock))))) {
      $0.user = .init(data: .mock)
      $0.history.userConnection = .established(welcomeDismissed: false)
    }

    await store.receive(.websocket(.connectedSuccessfully))

    expect(savedState).toEqual(.mock)
    await expect(apiUserToken).toEqual(UserData.mock.token)

    await store.send(.menuBar(.welcomeAdminClicked)) {
      $0.history.userConnection = .established(welcomeDismissed: true)
    }
  }

  func testHistoryUserConnectionError() async {
    let store = TestStore(initialState: AppReducer.State(), reducer: AppReducer())
    store.dependencies.api.connectUser = { _ in throw TestErr("Oh no!") }
    let helpClickedSpy = ActorIsolated(false)
    store.dependencies.device.openWebUrl = { _ in await helpClickedSpy.setValue(true) }

    await store.send(.menuBar(.connectClicked)) {
      $0.history.userConnection = .enteringConnectionCode
    }

    await store.send(.menuBar(.connectSubmit(code: 111_222))) {
      $0.history.userConnection = .connecting
    }

    await store.receive(.history(.userConnection(.connect(.failure(TestErr("Oh no!")))))) {
      $0.history.userConnection =
        .connectFailed("Please try again, or contact help if the problem persists.")
    }

    await store.send(.menuBar(.connectFailedHelpClicked))
    await expect(helpClickedSpy).toEqual(true)

    await store.send(.menuBar(.retryConnectClicked)) {
      $0.history.userConnection = .enteringConnectionCode
    }
  }
}

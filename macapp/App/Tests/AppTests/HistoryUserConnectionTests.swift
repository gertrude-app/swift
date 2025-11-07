import ComposableArchitecture
import Gertie
import TestSupport
import XCTest
import XExpect

@testable import App

final class HistoryUserConnectionTests: XCTestCase {
  @MainActor
  func testHistoryUserConnectionHappyPath() async {
    let (store, _) = AppReducer.testStore()
    store.dependencies.api.connectUser = { _ in .mock }

    store.deps.api.checkIn = { _ in throw TestErr("stop check in") }
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn

    let setUserToken = spy(on: UUID.self, returning: ())
    store.deps.api.setUserToken = setUserToken.fn

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

    await expect(saveState.calls).toEqual([.mock])
    await expect(setUserToken.calls).toEqual([UserData.mock.token])

    await store.send(.menuBar(.welcomeAdminClicked)) {
      $0.history.userConnection = .established(welcomeDismissed: true)
    }
  }

  @MainActor
  func testHistoryUserConnectionError() async {
    let (store, _) = AppReducer.testStore()
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
        .connectFailed(
          "Sorry, something went wrong. Please try again, or contact help if the problem persists.",
        )
    }

    await store.send(.menuBar(.connectFailedHelpClicked))
    await expect(helpClickedSpy).toEqual(true)

    await store.send(.menuBar(.retryConnectClicked)) {
      $0.history.userConnection = .notConnected
    }
  }
}

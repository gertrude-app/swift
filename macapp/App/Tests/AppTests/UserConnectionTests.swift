import ComposableArchitecture
import Core
import TestSupport
import XCTest
import XExpect

@testable import App

@MainActor final class UserConnectionTests: XCTestCase {
  func testDisconnectingUserFromAdminWindowStateAndEffects() async {
    await disconnectTest(
      action: .adminAuthed(.adminWindow(.webview(.disconnectUserClicked))),
      setupState: {
        $0.adminWindow.windowOpen = true
        $0.menuBar.dropdownOpen = false
      },
      assertState: {
        $0.adminWindow.windowOpen = false
        $0.menuBar.dropdownOpen = true
      }
    )
  }

  func testDisconnectingUserFromWebsocketMsgStateAndEffects() async {
    await disconnectTest(
      action: .websocket(.receivedMessage(.userDeleted)),
      extraReceivedActions: [
        .focusedNotification(.text(
          "Child deleted",
          "The child associated with this computer was deleted. You'll need to connect to a different child, or quit the app."
        )),
      ]
    )
  }

  func testDisconnectingUserFromMissingUserTokenStateAndEffects() async {
    await disconnectTest(
      action: .history(.userConnection(.disconnectMissingUser)),
      extraReceivedActions: [
        .focusedNotification(.text(
          "Child deleted",
          "The child associated with this computer was deleted. You'll need to connect to a different child, or quit the app."
        )),
      ]
    )
  }
}

@MainActor func disconnectTest(
  action: AppReducer.Action,
  setupState: @escaping (inout AppReducer.State) -> Void = { _ in },
  setupStore: (TestStoreOf<AppReducer>) -> Void = { _ in },
  assertState: @escaping (inout AppReducer.State) -> Void = { _ in },
  extraReceivedActions: [AppReducer.Action] = []
) async {
  let (store, bgQueue) = AppReducer.testStore {
    $0.user.data = .mock
    $0.history.userConnection = .established(welcomeDismissed: true)
    setupState(&$0)
  }

  store.exhaustivity = .on
  await store.withExhaustivity(.off) {
    await store.send(.startProtecting(user: .mock))
    await store.skipReceivedActions()
    await bgQueue.advance(by: .seconds(60))
    await store.receive(.heartbeat(.everyMinute)) // <-- heartbeat is running
  }

  let clearApiToken = mock(always: ())
  store.deps.api.clearUserToken = clearApiToken.fn
  let saveState = spy(on: Persistent.State.self, returning: ())
  store.deps.storage.savePersistentState = saveState.fn
  let xpcDisconnect = mock(once: Result<Void, XPCErr>.success(()))
  store.deps.filterXpc.disconnectUser = xpcDisconnect.fn
  let disableLaunchAtLogin = mock(always: ())
  store.deps.app.disableLaunchAtLogin = disableLaunchAtLogin.fn
  store.deps.monitoring.commitPendingKeystrokes = { _ in fatalError() }
  store.deps.monitoring.takeScreenshot = { _ in fatalError() }
  setupStore(store)

  await store.send(action) {
    $0.user = .init()
    $0.history.userConnection = .notConnected
    assertState(&$0)
  }

  for action in extraReceivedActions {
    await store.receive(action)
  }

  await expect(clearApiToken.invocations).toEqual(1)
  await expect(saveState.invocations.value).toHaveCount(1)
  await expect(xpcDisconnect.invocations).toEqual(1)
  await expect(disableLaunchAtLogin.invocations).toEqual(1)

  // no heartbeat actions received, no timed screenshots
  await bgQueue.advance(by: .seconds(60 * 10))
}

import ComposableArchitecture
import Core
import TestSupport
import XCore
import XCTest
import XExpect

@testable import App

@MainActor final class BlockedRequestsTests: XCTestCase {
  func testBlockedReqsFromFilterAddedToState() async {
    let (store, _) = AppReducer.testStore()

    let req = BlockedRequest.mock
    await store.send(.xpc(.receivedExtensionMessage(.blockedRequest(req)))) {
      $0.blockedRequests.requests = [req]
    }

    let streamBlocksSpy = ActorIsolated<Bool?>(nil)
    store.deps.filterXpc.setBlockStreaming = {
      await streamBlocksSpy.setValue($0)
      return .success(())
    }

    await store.send(.menuBar(.viewNetworkTrafficClicked)) {
      $0.blockedRequests.windowOpen = true
    }
    await expect(streamBlocksSpy).toEqual(true)
  }

  func testSimpleActions() async {
    var state = BlockedRequestsFeature.State()
    let req = BlockedRequest.mock
    state.requests = [req, .mock, .mock]
    let store = TestStore(initialState: state, reducer: BlockedRequestsFeature.Reducer())

    let blockStreamSpy = ActorIsolated<[Bool]>([])
    store.deps.filterXpc.setBlockStreaming = {
      await blockStreamSpy.append($0)
      return .success(())
    }

    await store.send(.openWindow) {
      $0.windowOpen = true
    }
    await expect(blockStreamSpy).toEqual([true])

    await store.send(.webview(.filterTextUpdated(text: "foo"))) {
      $0.filterText = "foo"
    }
    await expect(blockStreamSpy).toEqual([true, true])

    await store.send(.webview(.tcpOnlyToggled)) {
      $0.tcpOnly.toggle()
    }
    await expect(blockStreamSpy).toEqual([true, true, true])

    await store.send(.webview(.toggleRequestSelected(id: req.id))) {
      $0.selectedRequestIds = [req.id]
    }

    await store.send(.webview(.toggleRequestSelected(id: req.id))) {
      $0.selectedRequestIds = []
    }

    await store.send(.webview(.toggleRequestSelected(id: req.id))) {
      $0.selectedRequestIds = [req.id]
    }

    await store.send(.webview(.clearRequestsClicked)) {
      $0.requests = []
      $0.selectedRequestIds = []
    }
    await expect(blockStreamSpy).toEqual([true, true, true, true])

    await store.send(.closeWindow) {
      $0.windowOpen = false
    }
    await expect(blockStreamSpy).toEqual([true, true, true, true, false])
  }

  func testSubmitUnlockRequests() async {
    var state = BlockedRequestsFeature.State()
    let blocked = BlockedRequest.mock
    state.requests = [blocked]
    state.selectedRequestIds = [blocked.id]
    let store = TestStore(initialState: state, reducer: BlockedRequestsFeature.Reducer())
    store.deps.api.createUnlockRequests = { _ in }
    let scheduler = DispatchQueue.test
    store.deps.mainQueue = scheduler.eraseToAnyScheduler()

    await store.send(.webview(.unlockRequestSubmitted(comment: "please"))) {
      $0.createUnlockRequests = .ongoing
    }

    await store.receive(.createUnlockRequests(.success(.init()))) {
      $0.createUnlockRequests = .succeeded
      $0.selectedRequestIds = []
    }

    await scheduler.advance(by: 9)
    expect(store.state.createUnlockRequests).toEqual(.succeeded)
    await scheduler.advance(by: 1)

    await store.receive(.createUnlockRequestsSuccessTimedOut) {
      $0.createUnlockRequests = .idle
    }
  }

  func testTogglingRequestReturnsToIdleFromSuccess() async {
    var state = BlockedRequestsFeature.State()
    let req1 = BlockedRequest.mock
    let req2 = BlockedRequest.mock
    let req3 = BlockedRequest.mock
    state.requests = [req1, req2, req3]
    state.selectedRequestIds = [req1.id]
    let store = TestStore(initialState: state, reducer: BlockedRequestsFeature.Reducer())
    store.deps.api.createUnlockRequests = { _ in }
    store.deps.mainQueue = DispatchQueue.test.eraseToAnyScheduler()

    await store.send(.webview(.unlockRequestSubmitted(comment: "please"))) {
      $0.createUnlockRequests = .ongoing
    }

    await store.receive(.createUnlockRequests(.success(.init()))) {
      $0.createUnlockRequests = .succeeded
      $0.selectedRequestIds = []
    }

    // we're showing the "success" state here, but the user clicks to toggle another request
    // so we want to bring up the panel allowing them to submit, to switch to idle
    await store.send(.webview(.toggleRequestSelected(id: req2.id))) {
      $0.selectedRequestIds = [req2.id]
      $0.createUnlockRequests = .idle
    }

    store.deps.api.createUnlockRequests = { _ in throw TestErr("") }

    await store.send(.webview(.unlockRequestSubmitted(comment: "please"))) {
      $0.createUnlockRequests = .ongoing
    }

    await store.receive(.createUnlockRequests(.failure(TestErr("")))) {
      $0.createUnlockRequests =
        .failed(error: "Please try again, or contact help if the problem persists.")
    }

    // toggling a request brings back to idle so the user can try again
    await store.send(.webview(.toggleRequestSelected(id: req3.id))) {
      $0.selectedRequestIds = [req2.id, req3.id]
      $0.createUnlockRequests = .idle
    }
  }

  func testTypescriptEncodedActionsDecodeProperly() throws {
    let cases: [(String, BlockedRequestsFeature.Action.View)] = [
      (
        """
        {
          "case": "filterTextUpdated",
          "text": "foo"
        }
        """,
        .filterTextUpdated(text: "foo")
      ),
      (
        #"{"case":"requestFailedTryAgainClicked"}"#,
        .requestFailedTryAgainClicked
      ),
      (
        """
        {
          "case": "unlockRequestSubmitted",
          "comment": "please dad!"
        }
        """,
        .unlockRequestSubmitted(comment: "please dad!")
      ),
      (
        #"{"case":"unlockRequestSubmitted"}"#,
        .unlockRequestSubmitted(comment: nil)
      ),
      (
        """
        {
          "case": "toggleRequestSelected",
          "id": "00000000-0000-0000-0000-000000000000"
        }
        """,
        .toggleRequestSelected(id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
      ),
      (#"{"case":"tcpOnlyToggled"}"#, .tcpOnlyToggled),
      (#"{"case":"clearRequestsClicked"}"#, .clearRequestsClicked),
      (#"{"case":"closeWindow"}"#, .closeWindow),
    ]
    for (json, expected) in cases {
      let decoded = try JSON.decode(json, as: BlockedRequestsFeature.Action.View.self)
      expect(decoded).toEqual(expected)
    }
  }
}

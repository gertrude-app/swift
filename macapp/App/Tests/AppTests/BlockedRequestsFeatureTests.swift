import ComposableArchitecture
import Core
import TestSupport
import XCore
import XCTest
import XExpect

@testable import App

@MainActor final class BlockedRequestsFeatureTests: XCTestCase {
  func testFilterCommunicationConfirmationSucceeded() async {
    let (store, _) = AppReducer.testStore {
      $0.blockedRequests.filterCommunicationConfirmed = false
    }

    // can't connect, or repair connection
    store.deps.filterXpc.checkConnectionHealth = { .success(()) }

    await store.send(.menuBar(.viewNetworkTrafficClicked)) {
      $0.blockedRequests.filterCommunicationConfirmed = nil // <-- nils out for fresh confirmation
      $0.blockedRequests.windowOpen = true
    }

    await store.receive(.blockedRequests(.receivedFilterCommunicationConfirmation(true))) {
      $0.blockedRequests.filterCommunicationConfirmed = true
    }
  }

  func testFilterCommunicationConfirmationFailed() async {
    let (store, _) = AppReducer.testStore {
      $0.blockedRequests.filterCommunicationConfirmed = true
    }

    // can't connect, or repair connection
    store.deps.filterXpc.checkConnectionHealth = { .failure(.unknownError("???")) }
    store.deps.filterXpc.establishConnection = { .failure(.unknownError("???")) }

    await store.send(.menuBar(.viewNetworkTrafficClicked)) {
      $0.blockedRequests.filterCommunicationConfirmed = nil // <-- nils out for fresh confirmation
      $0.blockedRequests.windowOpen = true
    }

    await store.receive(.blockedRequests(.receivedFilterCommunicationConfirmation(false))) {
      $0.blockedRequests.filterCommunicationConfirmed = false
    }
  }

  func testClickingAdministrateFromFilterCommFailureOpensAdmin() async {
    let (store, _) = AppReducer.testStore {
      $0.adminWindow.windowOpen = false
      $0.blockedRequests.windowOpen = true
    }

    await store
      .send(.adminAuthed(.blockedRequests(.webview(.noFilterCommunicationAdministrateClicked)))) {
        $0.adminWindow.windowOpen = true
        $0.adminWindow.screen = .healthCheck
        $0.blockedRequests.windowOpen = false
      }
  }

  func testBlockedReqsFromFilterAddedToState() async {
    let (store, _) = AppReducer.testStore()

    let setBlockStreaming = spy(on: Bool.self, returning: Result<_, XPCErr>.success(()))
    store.deps.filterXpc.setBlockStreaming = setBlockStreaming.fn

    await store.send(.menuBar(.viewNetworkTrafficClicked)) {
      $0.blockedRequests.windowOpen = true
    }
    await expect(setBlockStreaming.invocations).toEqual([true])

    let req = BlockedRequest.mock
    await store.send(.xpc(.receivedExtensionMessage(.blockedRequest(req)))) {
      $0.blockedRequests.requests = [req]
    }
  }

  func testMergeableBlockedRequestNotAdded() async {
    let (store, _) = AppReducer.testStore()

    let req1 = BlockedRequest(app: .mock, url: "https://foo.com/1")
    await store.send(.xpc(.receivedExtensionMessage(.blockedRequest(req1)))) {
      $0.blockedRequests.requests = [req1]
    }

    let req2 = BlockedRequest(app: .mock, url: "https://foo.com/1") // <-- should merge
    await store.send(.xpc(.receivedExtensionMessage(.blockedRequest(req2)))) {
      $0.blockedRequests.requests = [req1]
    }
  }

  func testSimpleActions() async {
    let req = BlockedRequest.mock
    let (store, _) = AppReducer.testStore {
      $0.blockedRequests.requests = [req, .mock, .mock]
    }

    let setBlockStreaming = spy(on: Bool.self, returning: Result<_, XPCErr>.success(()))
    store.deps.filterXpc.setBlockStreaming = setBlockStreaming.fn

    await store.send(.menuBar(.viewNetworkTrafficClicked)) {
      $0.blockedRequests.windowOpen = true
    }
    await expect(setBlockStreaming.invocations).toEqual([true])

    await store.send(.blockedRequests(.webview(.filterTextUpdated(text: "foo")))) {
      $0.blockedRequests.filterText = "foo"
    }
    await expect(setBlockStreaming.invocations).toEqual([true, true])

    await store.send(.blockedRequests(.webview(.tcpOnlyToggled))) {
      $0.blockedRequests.tcpOnly = false
    }
    await expect(setBlockStreaming.invocations).toEqual([true, true, true])

    await store.send(.blockedRequests(.webview(.toggleRequestSelected(id: req.id)))) {
      $0.blockedRequests.selectedRequestIds = [req.id]
    }

    await store.send(.blockedRequests(.webview(.toggleRequestSelected(id: req.id)))) {
      $0.blockedRequests.selectedRequestIds = []
    }

    await store.send(.blockedRequests(.webview(.toggleRequestSelected(id: req.id)))) {
      $0.blockedRequests.selectedRequestIds = [req.id]
    }

    await store.send(.blockedRequests(.webview(.clearRequestsClicked))) {
      $0.blockedRequests.requests = []
      $0.blockedRequests.selectedRequestIds = []
    }
    await expect(setBlockStreaming.invocations).toEqual([true, true, true, true])

    await store.send(.blockedRequests(.closeWindow)) {
      $0.blockedRequests.windowOpen = false
    }
    await expect(setBlockStreaming.invocations).toEqual([true, true, true, true, false])
  }

  func testSubmitUnlockRequests() async {
    var state = BlockedRequestsFeature.State()
    let blocked = BlockedRequest.mock
    state.requests = [blocked]
    state.selectedRequestIds = [blocked.id]
    let store = TestStore(initialState: state, reducer: { BlockedRequestsFeature.Reducer() })
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
    let store = TestStore(initialState: state, reducer: { BlockedRequestsFeature.Reducer() })
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

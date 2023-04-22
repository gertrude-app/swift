import ComposableArchitecture
import Core
import TestSupport
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

  func testFeatureReducer() async {
    var state = BlockedRequestsFeature.State()
    state.requests = [.mock]
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

    await store.send(.filterTextUpdated(text: "foo")) {
      $0.filterText = "foo"
    }
    await expect(blockStreamSpy).toEqual([true, true])

    await store.send(.tcpOnlyToggled) {
      $0.tcpOnly.toggle()
    }
    await expect(blockStreamSpy).toEqual([true, true, true])

    await store.send(.clearRequestsClicked) {
      $0.requests = []
    }
    await expect(blockStreamSpy).toEqual([true, true, true, true])

    await store.send(.closeWindow) {
      $0.windowOpen = false
    }
    await expect(blockStreamSpy).toEqual([true, true, true, true, false])
  }
}

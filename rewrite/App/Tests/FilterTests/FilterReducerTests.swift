import Combine
import ComposableArchitecture
import Core
import Shared
import TestSupport
import XCTest
import XExpect

@testable import Filter

@MainActor final class FilterReducerTests: XCTestCase {
  func testExtensionStarted_Exhaustive() async {
    let (store, _) = Filter.testStore(exhaustive: true)
    let subject = PassthroughSubject<XPCEvent.Filter, Never>()
    store.deps.xpc.events = { subject.eraseToAnyPublisher() }
    let xpcStarted = ActorIsolated(false)
    store.deps.xpc.startListener = { await xpcStarted.setValue(true) }

    await store.send(.extensionStarted)
    await expect(xpcStarted).toEqual(true)

    let descriptor = AppDescriptor(bundleId: "com.foo")
    await store.send(.cacheAppDescriptor("com.foo", descriptor)) {
      $0.appCache["com.foo"] = descriptor
    }

    let key = FilterKey(id: .init(), key: .skeleton(scope: .bundleId("com.foo")))
    let manifest = AppIdManifest(apps: ["Lol": ["com.lol"]])
    let message = XPCEvent.Filter
      .receivedAppMessage(.userRules(userId: 502, keys: [key], manifest: manifest))

    subject.send(message)

    await store.receive(.xpc(message)) {
      $0.userKeys[502] = [key]
      $0.appIdManifest = manifest
      $0.appCache = [:] // clears out app cache when new manifest is received
    }

    subject.send(completion: .finished)
  }

  func testStreamBlockedRequests() async {
    let (store, _) = Filter.testStore(exhaustive: true)

    // user not streaming, so we won't send the request
    store.deps.xpc.sendBlockedRequest = { _, _ in fatalError() }

    // in reality, the FilterDataProvider would never send a block
    // to the store if the user wasn't streaming, but this just ensures
    // that the logic in the reducer correctly ignores blocks with no listener
    await store.send(.flowBlocked(FilterFlow(userId: 502)))

    await store.send(.xpc(.receivedAppMessage(.setBlockStreaming(
      enabled: true,
      userId: 502
    )))) {
      $0.blockListeners[502] = Date(timeIntervalSince1970: 60 * 5)
    }

    // now we're streaming blocks for 502
    let sentBlocks = ActorIsolated([Both<uid_t, BlockedRequest>]())
    store.deps.xpc.sendBlockedRequest = { userId, request in
      await sentBlocks.append(Both(userId, request))
    }

    let flow = FilterFlow(userId: 502)
    await store.send(.flowBlocked(flow))
    await store.send(.flowBlocked(FilterFlow(userId: 503))) // <-- different user
    await expect(sentBlocks).toEqual([Both(502, flow.blockedRequest)])

    await store.send(.xpc(.receivedAppMessage(.setBlockStreaming(
      enabled: false,
      userId: 502
    )))) {
      $0.blockListeners = [:]
    }

    // no more blocks should be sent
    store.deps.xpc.sendBlockedRequest = { _, _ in fatalError() }
    await store.send(.flowBlocked(FilterFlow(userId: 502)))
  }

  func testBlockStreamingExpiration() async {
    let (store, _) = Filter.testStore()

    let sentBlocks = ActorIsolated([Both<uid_t, BlockedRequest>]())
    store.deps.xpc.sendBlockedRequest = { userId, request in
      await sentBlocks.append(Both(userId, request))
    }

    await store.send(.xpc(.receivedAppMessage(.setBlockStreaming(
      enabled: true,
      userId: 502
    )))) {
      $0.blockListeners[502] = Date(timeIntervalSince1970: 60 * 5)
    }

    // one second BEFORE expiration
    store.deps.date.now = Date(timeIntervalSince1970: 60 * 5 - 1)

    let flow1 = FilterFlow(userId: 502)
    await store.send(.flowBlocked(flow1))
    await expect(sentBlocks).toEqual([Both(502, flow1.blockedRequest)])

    // one second AFTER expiration
    store.deps.date.now = Date(timeIntervalSince1970: 60 * 5 + 1)
    await store.send(.flowBlocked(FilterFlow(userId: 502))) {
      $0.blockListeners = [:]
    }

    await expect(sentBlocks).toEqual([Both(502, flow1.blockedRequest)])
  }
}

// helpers

extension Filter {
  static func testStore(exhaustive: Bool = false)
    -> (TestStoreOf<Filter>, TestSchedulerOf<DispatchQueue>) {
    let store = TestStore(initialState: State(), reducer: Filter())
    store.exhaustivity = exhaustive ? .on : .off
    let scheduler = DispatchQueue.test
    store.deps.mainQueue = .immediate
    store.deps.date.now = Date(timeIntervalSince1970: 0)
    return (store, scheduler)
  }
}

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
    store.deps.storage.loadPersistentState = { .init(
      userKeys: [:],
      appIdManifest: .init(),
      exemptUsers: [501]
    ) }

    await store.send(.extensionStarted)
    await expect(xpcStarted).toEqual(true)

    await store.receive(.loadedPersistentState(.init(
      userKeys: [:],
      appIdManifest: .init(),
      exemptUsers: [501]
    ))) {
      $0.exemptUsers = [501]
    }

    let descriptor = AppDescriptor(bundleId: "com.foo")
    await store.send(.cacheAppDescriptor("com.foo", descriptor)) {
      $0.appCache["com.foo"] = descriptor
    }

    let key = FilterKey(id: .init(), key: .skeleton(scope: .bundleId("com.foo")))
    let manifest = AppIdManifest(apps: ["Lol": ["com.lol"]])
    let message = XPCEvent.Filter
      .receivedAppMessage(.userRules(userId: 502, keys: [key], manifest: manifest))

    let savedState = ActorIsolated<Persistent.State?>(nil)
    store.deps.storage.savePersistentState = { await savedState.setValue($0) }

    subject.send(message)

    await store.receive(.xpc(message)) {
      $0.userKeys[502] = [key]
      $0.appIdManifest = manifest
      $0.appCache = [:] // clears out app cache when new manifest is received
    }

    await expect(savedState).toEqual(.init(
      userKeys: [502: [key]], //  <-- new info from user rules
      appIdManifest: manifest, // <-- new info from user rules
      exemptUsers: [501] // <-- preserving existing unchanged data
    ))

    subject.send(completion: .finished)
  }

  func testStreamBlockedRequests() async {
    let (store, _) = Filter.testStore(exhaustive: true)

    // user not streaming, so we won't send the request
    store.deps.xpc.sendBlockedRequest = { _, _ in fatalError() }

    // in reality, the FilterDataProvider would never send a block
    // to the store if the user wasn't streaming, but this just ensures
    // that the logic in the reducer correctly ignores blocks with no listener
    await store.send(.flowBlocked(FilterFlow(userId: 502), .mock))

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
    await store.send(.flowBlocked(flow, .mock))
    await store.send(.flowBlocked(FilterFlow(userId: 503), .mock)) // <-- different user
    await expect(sentBlocks).toEqual([Both(502, flow.testBlockedReq())])

    await store.send(.xpc(.receivedAppMessage(.setBlockStreaming(
      enabled: false,
      userId: 502
    )))) {
      $0.blockListeners = [:]
    }

    // no more blocks should be sent
    store.deps.xpc.sendBlockedRequest = { _, _ in fatalError() }
    await store.send(.flowBlocked(FilterFlow(userId: 502), .mock))
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
    let flow1Block = flow1.testBlockedReq(time: store.deps.date.now)
    await store.send(.flowBlocked(flow1, .mock))
    await expect(sentBlocks).toEqual([Both(502, flow1Block)])

    // one second AFTER expiration
    store.deps.date.now = Date(timeIntervalSince1970: 60 * 5 + 1)
    await store.send(.flowBlocked(FilterFlow(userId: 502), .mock)) {
      $0.blockListeners = [:]
    }

    await expect(sentBlocks).toEqual([Both(502, flow1Block)])
  }

  func testDisconnectUser() async {
    let key1 = FilterKey(id: .init(), key: .skeleton(scope: .bundleId("com.foo")))
    let key2 = FilterKey(id: .init(), key: .skeleton(scope: .bundleId("com.foo")))
    let otherUserSuspension = FilterSuspension(scope: .mock, duration: 600)
    let (store, _) = Filter.testStore {
      $0.userKeys = [
        502: [key1],
        503: [key2],
      ]
      $0.suspensions = [
        502: .init(scope: .mock, duration: 600),
        503: otherUserSuspension,
      ]
      // a user being disconnected should almost never be exempt
      // but this just tests the failsafe that we also remove exempt status
      $0.exemptUsers = [501, 502]
    }

    let save = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = save.fn

    await store.send(.xpc(.receivedAppMessage(.disconnectUser(userId: 502)))) {
      $0.userKeys = [503: [key2]]
      $0.suspensions = [503: otherUserSuspension]
      $0.exemptUsers = [501]
    }

    await expect(save.invocations).toEqual([.init(
      userKeys: [503: [key2]],
      appIdManifest: .init(),
      exemptUsers: [501]
    )])
  }

  func testEndFilterSuspension() async {
    let otherUserSuspension = FilterSuspension(scope: .mock, duration: 600)
    let (store, _) = Filter.testStore {
      $0.suspensions = [
        502: .init(scope: .mock, duration: 600),
        503: otherUserSuspension,
      ]
    }

    await store.send(.xpc(.receivedAppMessage(.endFilterSuspension(userId: 502)))) {
      $0.suspensions = [503: otherUserSuspension]
    }
  }

  func testStartFilterSuspension() async {
    let otherUserSuspension = FilterSuspension(scope: .mock, duration: 600)
    let (store, _) = Filter.testStore {
      $0.suspensions = [503: otherUserSuspension]
    }

    await store.send(.xpc(.receivedAppMessage(.suspendFilter(userId: 502, duration: 600)))) {
      $0.suspensions = [
        502: .init(scope: .unrestricted, duration: 600, now: store.deps.date.now),
        503: otherUserSuspension,
      ]
    }
  }
}

// helpers

extension Filter {
  static func testStore(
    exhaustive: Bool = false,
    mutateState: @escaping (inout State) -> Void = { _ in }
  ) -> (TestStoreOf<Filter>, TestSchedulerOf<DispatchQueue>) {
    var state = State()
    mutateState(&state)
    let store = TestStore(initialState: state, reducer: Filter())
    store.exhaustivity = exhaustive ? .on : .off
    let scheduler = DispatchQueue.test
    store.deps.mainQueue = .immediate
    store.deps.date.now = TEST_NOW
    store.deps.uuid = .constant(TEST_ID)
    return (store, scheduler)
  }
}

let TEST_NOW = Date(timeIntervalSince1970: 0)
let TEST_ID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

extension FilterFlow {
  func testBlockedReq(id: UUID = TEST_ID, time: Date = TEST_NOW) -> BlockedRequest {
    BlockedRequest(
      id: id,
      time: time,
      app: .mock,
      url: url,
      hostname: hostname,
      ipAddress: ipAddress,
      ipProtocol: ipProtocol
    )
  }
}

extension AppDescriptor {
  static let mock = AppDescriptor(bundleId: "com.mock.app")
}

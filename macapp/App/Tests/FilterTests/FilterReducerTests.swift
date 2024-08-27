import Combine
import ComposableArchitecture
import Core
import Gertie
import TestSupport
import XCTest
import XExpect

@testable import Filter

final class FilterReducerTests: XCTestCase {
  @MainActor
  func testExtensionStarted_Exhaustive() async {
    let (store, mainQueue) = Filter.testStore(exhaustive: true)
    let subject = PassthroughSubject<XPCEvent.Filter, Never>()
    store.deps.filterExtension = .mock
    store.deps.xpc.events = { subject.eraseToAnyPublisher() }
    store.deps.xpc.stopListener = {}
    let startListener = mock(always: ())
    store.deps.xpc.startListener = startListener.fn
    store.deps.storage.loadPersistentState = { .init(
      userKeys: [:],
      appIdManifest: .init(),
      exemptUsers: [501]
    ) }

    await store.send(.extensionStarted)
    await expect(startListener.called).toEqual(true)

    await store.receive(.loadedPersistentState(.init(
      userKeys: [:],
      appIdManifest: .init(),
      exemptUsers: [501]
    ))) {
      $0.exemptUsers = [501]
    }

    let descriptor = AppDescriptor(bundleId: "com.foo")

    // empty bundle ids are NOT cached
    await store.send(.cacheAppDescriptor("", .mock))

    await store.send(.cacheAppDescriptor("com.foo", descriptor)) {
      $0.appCache["com.foo"] = descriptor
    }

    let key = FilterKey(id: .init(), key: .skeleton(scope: .bundleId("com.foo")))
    let manifest = AppIdManifest(apps: ["Lol": ["com.lol"]])
    let message = XPCEvent.Filter
      .receivedAppMessage(.userRules(userId: 502, keys: [key], manifest: manifest))

    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn

    subject.send(message)

    await mainQueue.advance(by: .seconds(1))

    await store.receive(.xpc(message)) {
      $0.userKeys[502] = [key]
      $0.appIdManifest = manifest
      $0.appCache = [:] // clears out app cache when new manifest is received
    }

    await expect(saveState.calls).toEqual([.init(
      userKeys: [502: [key]], //  <-- new info from user rules
      appIdManifest: manifest, // <-- new info from user rules
      exemptUsers: [501] // <-- preserving existing unchanged data
    )])

    subject.send(completion: .finished)
    await mainQueue.advance(by: .seconds(59))
    await store.receive(.heartbeat)
    await store.send(.extensionStopping)
  }

  @MainActor
  func testReceivingRulesWithAtLeastOneKeyClearsExemptStatus() async {
    let (store, _) = Filter.testStore {
      $0.exemptUsers = [501, 504]
    }
    store.deps.filterExtension = .mock
    store.deps.storage = .mock

    await store.send(.xpc(.receivedAppMessage(.userRules(
      userId: 501, // we get rules about user 501
      keys: [.mock],
      manifest: .mock
    )))) {
      $0.exemptUsers = [504] // ... so they are removed from the exempt list
    }
  }

  // this is a bit of a hack until we support the concept of "non-filtered" children
  // see https://github.com/gertrude-app/project/issues/163
  @MainActor
  func testReceivingRulesWithZeroKeysDoesNotClearExemptStatus() async {
    let (store, _) = Filter.testStore {
      $0.exemptUsers = [501, 504]
    }
    store.deps.filterExtension = .mock
    store.deps.storage = .mock

    await store.send(.xpc(.receivedAppMessage(.userRules(
      userId: 501, // we get rules about user 501
      keys: [], // <-- but there are ZERO keys
      manifest: .mock
    )))) {
      $0.exemptUsers = [501, 504] // ... so they are NOT removed from the exempt list
    }
  }

  @MainActor
  func testStreamBlockedRequests() async {
    let (store, _) = Filter.testStore(exhaustive: true)
    store.deps.filterExtension = .mock

    // user not streaming, so we won't send the request
    store.deps.xpc.sendBlockedRequest = { _, _ in fatalError() }

    // in reality, the FilterDataProvider would never send a block
    // to the store if the user wasn't streaming, but this test verifies
    // that the logic in the reducer correctly ignores blocks with no listener
    await store.send(.flowBlocked(FilterFlow(userId: 502), .mock))

    await store.send(.xpc(.receivedAppMessage(.setBlockStreaming(
      enabled: true,
      userId: 502
    )))) {
      $0.blockListeners[502] = Date(timeIntervalSince1970: 60 * 5)
    }

    // now we're streaming blocks for 502
    let sendBlocked = spy2(on: (uid_t.self, BlockedRequest.self), returning: ())
    store.deps.xpc.sendBlockedRequest = sendBlocked.fn

    let flow = FilterFlow(userId: 502)
    await store.send(.flowBlocked(flow, .mock))
    await store.send(.flowBlocked(FilterFlow(userId: 503), .mock)) // <-- different user
    await expect(sendBlocked.calls).toEqual([Both(502, flow.testBlockedReq())])

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

  @MainActor
  func testBlockStreamingExpiration() async {
    let (store, _) = Filter.testStore()
    let sendBlocked = spy2(on: (uid_t.self, BlockedRequest.self), returning: ())
    store.deps.xpc.sendBlockedRequest = sendBlocked.fn
    store.deps.filterExtension = .mock

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
    await expect(sendBlocked.calls).toEqual([Both(502, flow1Block)])

    // one second AFTER expiration
    store.deps.date.now = Date(timeIntervalSince1970: 60 * 5 + 1)
    await store.send(.flowBlocked(FilterFlow(userId: 502), .mock)) {
      $0.blockListeners = [:]
    }

    await expect(sendBlocked.calls).toEqual([Both(502, flow1Block)])
  }

  @MainActor
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
    store.deps.filterExtension = .mock

    await store.send(.xpc(.receivedAppMessage(.disconnectUser(userId: 502)))) {
      $0.userKeys = [503: [key2]]
      $0.suspensions = [503: otherUserSuspension]
      $0.exemptUsers = [501]
    }

    await expect(save.calls).toEqual([.init(
      userKeys: [503: [key2]],
      appIdManifest: .init(),
      exemptUsers: [501]
    )])
  }

  @MainActor
  func testSetUserExemption() async {
    let (store, _) = Filter.testStore { $0.exemptUsers = [501] }
    store.deps.filterExtension = .mock

    let save = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = save.fn

    await store.send(.xpc(.receivedAppMessage(.setUserExemption(userId: 502, enabled: true)))) {
      $0.exemptUsers = [501, 502]
    }

    await store.send(.xpc(.receivedAppMessage(.setUserExemption(userId: 501, enabled: false)))) {
      $0.exemptUsers = [502]
    }

    await expect(save.calls).toEqual([
      .init(userKeys: [:], appIdManifest: .init(), exemptUsers: [501, 502]),
      .init(userKeys: [:], appIdManifest: .init(), exemptUsers: [502]),
    ])
  }

  @MainActor
  func testStartFilterSuspension() async {
    let otherUserSuspension = FilterSuspension(scope: .mock, duration: 600)
    let (store, mainQueue) = Filter.testStore {
      $0.suspensions = [503: otherUserSuspension]
    }
    store.deps.filterExtension = .mock

    let notifyExpired = spy(on: uid_t.self, returning: ())
    store.deps.xpc.notifyFilterSuspensionEnded = notifyExpired.fn

    await store.send(.xpc(.receivedAppMessage(.suspendFilter(userId: 502, duration: 600)))) {
      $0.suspensions = [
        502: .init(scope: .unrestricted, duration: 600, now: store.deps.date.now),
        503: otherUserSuspension,
      ]
    }

    await mainQueue.advance(by: .seconds(599))
    await expect(notifyExpired.called).toEqual(false)

    await mainQueue.advance(by: .seconds(1))
    await expect(notifyExpired.calls).toEqual([502])

    await store.receive(.suspensionTimerEnded(502)) {
      $0.suspensions[502] = nil
    }
  }

  @MainActor
  func testExtendSuspensionWhenReceivingASecond() async {
    let (store, mainQueue) = Filter.testStore {
      $0.suspensions = [:]
    }

    let time = ControllingNow(starting: .epoch, with: mainQueue)
    store.deps.date = time.generator

    store.deps.filterExtension = .mock

    let notifyExpired = spy(on: uid_t.self, returning: ())
    store.deps.xpc.notifyFilterSuspensionEnded = notifyExpired.fn

    await store.send(.xpc(.receivedAppMessage(.suspendFilter(userId: 502, duration: 600)))) {
      $0.suspensions = [
        502: .init(
          scope: .unrestricted,
          duration: 600,
          expiresAt: .epoch.advanced(by: .seconds(600))
        ),
      ]
    }

    await time.advance(seconds: 500)
    await expect(notifyExpired.called).toEqual(false)

    await store.send(.xpc(.receivedAppMessage(.suspendFilter(userId: 502, duration: 600)))) {
      $0.suspensions = [
        502: .init(
          scope: .unrestricted,
          duration: 600,
          expiresAt: .epoch.advanced(by: .seconds(500 + 600))
        ),
      ]
    }

    // going past first expiration does not notify app of end
    await time.advance(seconds: 200)
    await expect(notifyExpired.called).toEqual(false)

    // moving past second suspension end does notify and clean up
    await time.advance(seconds: 400)
    await expect(notifyExpired.calls).toEqual([502])

    await store.receive(.suspensionTimerEnded(502)) {
      $0.suspensions[502] = nil
    }
  }

  @MainActor
  func testCancelledFilterSuspension() async {
    let otherUserSuspension = FilterSuspension(scope: .mock, duration: 600)
    let (store, mainQueue) = Filter.testStore {
      $0.suspensions = [503: otherUserSuspension]
    }

    let notifyExpired = spy(on: uid_t.self, returning: ())
    store.deps.xpc.notifyFilterSuspensionEnded = notifyExpired.fn
    store.deps.filterExtension = .mock

    await store.send(.xpc(.receivedAppMessage(.suspendFilter(userId: 502, duration: 600)))) {
      $0.suspensions = [
        502: .init(scope: .unrestricted, duration: 600, now: store.deps.date.now),
        503: otherUserSuspension,
      ]
    }

    await store.send(.xpc(.receivedAppMessage(.endFilterSuspension(userId: 502)))) {
      $0.suspensions = [503: otherUserSuspension]
    }

    await mainQueue.advance(by: .seconds(600))
    await expect(notifyExpired.called).toEqual(false)
  }

  @MainActor
  func testSimultaneousSuspensions() async {
    let (store, mainQueue) = Filter.testStore()

    let notifyExpired = spy(on: uid_t.self, returning: ())
    store.deps.xpc.notifyFilterSuspensionEnded = notifyExpired.fn
    store.deps.filterExtension = .mock

    await store.send(.xpc(.receivedAppMessage(.suspendFilter(userId: 502, duration: 600)))) {
      $0.suspensions = [
        502: .init(scope: .unrestricted, duration: 600, now: store.deps.date.now),
      ]
    }

    await mainQueue.advance(by: .seconds(100))

    await store.send(.xpc(.receivedAppMessage(.suspendFilter(userId: 503, duration: 400)))) {
      $0.suspensions = [
        502: .init(scope: .unrestricted, duration: 600, now: store.deps.date.now),
        503: .init(scope: .unrestricted, duration: 400, now: store.deps.date.now),
      ]
    }

    await mainQueue.advance(by: .seconds(100))

    await store.send(.xpc(.receivedAppMessage(.suspendFilter(userId: 504, duration: 100)))) {
      $0.suspensions = [
        502: .init(scope: .unrestricted, duration: 600, now: store.deps.date.now),
        503: .init(scope: .unrestricted, duration: 400, now: store.deps.date.now),
        504: .init(scope: .unrestricted, duration: 100, now: store.deps.date.now),
      ]
    }

    await expect(notifyExpired.calls).toEqual([])

    // now let recently received suspension expire
    await mainQueue.advance(by: .seconds(100))
    await expect(notifyExpired.calls).toEqual([504])

    await store.receive(.suspensionTimerEnded(504)) {
      $0.suspensions = [
        502: .init(scope: .unrestricted, duration: 600, now: store.deps.date.now),
        503: .init(scope: .unrestricted, duration: 400, now: store.deps.date.now),
      ]
    }

    // cancelling one leaves other unaffected
    await mainQueue.advance(by: .seconds(100))
    await store.send(.xpc(.receivedAppMessage(.endFilterSuspension(userId: 503)))) {
      $0.suspensions = [
        502: .init(scope: .unrestricted, duration: 600, now: store.deps.date.now),
      ]
    }

    // last remaining suspension expires
    await mainQueue.advance(by: .seconds(200))
    await expect(notifyExpired.calls).toEqual([504, 502])
    await store.receive(.suspensionTimerEnded(502)) {
      $0.suspensions = [:]
    }
  }

  @MainActor
  func testHeartbeatCleansUpDanglingSuspensionFromSleepConfusingTimer() async {
    let (store, mainQueue) = Filter.testStore()
    store.deps.filterExtension = .mock
    store.deps.xpc.events = XPCClient.mock.events
    store.deps.xpc.startListener = {}
    store.deps.storage.loadPersistentState = StorageClient.mock.loadPersistentState

    let time = ControllingNow(starting: .epoch, with: mainQueue)
    store.deps.date = time.generator

    let notifyExpired = spy(on: uid_t.self, returning: ())
    store.deps.xpc.notifyFilterSuspensionEnded = notifyExpired.fn

    await store.send(.extensionStarted) // start hearbeat

    await store.send(.xpc(.receivedAppMessage(.suspendFilter(userId: 502, duration: 630)))) {
      $0.suspensions = [
        502: .init(
          scope: .unrestricted,
          duration: 60 * 10 + 30, // <-- expires 10.5 minutes after 1970
          now: Date(timeIntervalSince1970: 0)
        ),
      ]
    }

    await time.advance(seconds: 60 * 1) // advance 1 of 10 minutes and then..

    // ... the user puts the computer to sleep for an hour
    // upon wakeup, suspension is over, but the timer still has 9 minutes left.
    // the filter should notify the app immediately, so it can quit browsers
    // and the dangling timer should be cancelled so we don't quit twice
    time.simulateComputerSleep(seconds: 60 * 60)

    // on waking up, the suspension is still in memory, but it is now expired
    expect(store.state.suspensions[502]).not.toBeNil()

    // advance to next heartbeat, which should trigger cleanup logic
    await time.advance(seconds: 60 * 1)

    // assert that action is emitted, and suspension is removed from state...
    await store.receive(.staleSuspensionFound(502)) {
      $0.suspensions = [:]
    }

    // ... and we have notified the app so browsers can be quit
    await expect(notifyExpired.calls).toEqual([502])

    // now advance long enough that the confused timer would expire...
    await time.advance(seconds: 60 * 10)

    // and assert that we haven't notified the app again
    await expect(notifyExpired.calls).toEqual([502])
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
    let store = TestStore(initialState: state, reducer: { Filter() })
    store.exhaustivity = exhaustive ? .on : .off
    let scheduler = DispatchQueue.test
    store.deps.mainQueue = scheduler.eraseToAnyScheduler()
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

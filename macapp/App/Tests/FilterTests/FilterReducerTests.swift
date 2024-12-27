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
      userKeychains: [503: [.mock]],
      appIdManifest: .init(),
      exemptUsers: [501]
    ) }

    await store.send(.extensionStarted)
    await expect(startListener.called).toEqual(true)

    await store.receive(.loadedPersistentState(.init(
      userKeychains: [503: [.mock]],
      appIdManifest: .init(),
      exemptUsers: [501]
    ))) {
      $0.userKeychains = [503: [.mock]]
      $0.exemptUsers = [501]
    }

    let descriptor = AppDescriptor(bundleId: "com.foo")

    // empty bundle ids are NOT cached
    await store.send(.cacheAppDescriptor("", .mock))

    await store.send(.cacheAppDescriptor("com.foo", descriptor)) {
      $0.appCache["com.foo"] = descriptor
    }

    let keychain = RuleKeychain(keys: [.init(key: .skeleton(scope: .bundleId("com.foo")))])
    let manifest = AppIdManifest(apps: ["Lol": ["com.lol"]])
    let message = XPCEvent.Filter.receivedAppMessage(.userRules(
      userId: 502,
      keychains: [keychain],
      downtime: nil,
      manifest: manifest
    ))

    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn

    subject.send(message)

    await mainQueue.advance(by: .seconds(1))

    await store.receive(.xpc(message)) {
      $0.userKeychains[502] = [keychain]
      $0.appIdManifest = manifest
      $0.appCache = [:] // clears out app cache when new manifest is received
      $0.macappsAliveUntil[502] = .epoch + .macappAliveBuffer
    }

    await expect(saveState.calls).toEqual([.init(
      userKeychains: [503: [.mock], 502: [keychain]], //  <-- new info from user rules
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
      keychains: [.mock],
      downtime: nil,
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
      keychains: [], // <-- but there are ZERO keys
      downtime: nil,
      manifest: .mock
    )))) {
      $0.exemptUsers = [501, 504] // ... so they are NOT removed from the exempt list
    }
  }

  @MainActor
  func testReceivingDowntimeSetsUserDowntime() async {
    let (store, _) = Filter.testStore()
    store.deps.filterExtension = .mock
    store.deps.storage = .mock
    let save = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = save.fn

    let downtime = Downtime(window: "22:00-05:00")
    await store.send(.xpc(.receivedAppMessage(.userRules(
      userId: 502,
      keychains: [.mock],
      downtime: downtime,
      manifest: .mock
    )))) {
      $0.userDowntime[502] = downtime
    }

    await expect(save.calls).toEqual([.init(
      userKeychains: [502: [.mock]],
      userDowntime: [502: downtime.window], // <-- new downtime info saved
      appIdManifest: .mock,
      exemptUsers: []
    )])
  }

  @MainActor
  func testReceivingNilDowntimeClearsUserDowntime() async {
    let downtime = Downtime(window: .init(
      start: .init(hour: 22, minute: 0),
      end: .init(hour: 5, minute: 0)
    ))
    let (store, _) = Filter.testStore {
      $0.userDowntime[502] = downtime
    }
    store.deps.filterExtension = .mock
    store.deps.storage = .mock

    await store.send(.xpc(.receivedAppMessage(.userRules(
      userId: 502,
      keychains: [.mock],
      downtime: nil, // <-- downtime removed
      manifest: .mock
    )))) {
      $0.userDowntime = [:]
    }
  }

  @MainActor
  func testStreamBlockedRequests() async {
    let (store, _) = Filter.testStore(exhaustive: true)
    store.deps.filterExtension = .mock
    store.deps.date = .constant(.epoch)

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
      $0.blockListeners[502] = .epoch + .minutes(5)
      $0.macappsAliveUntil[502] = .epoch + .macappAliveBuffer
    }

    // now we're streaming blocks for 502
    let sendBlocked = spy2(on: (uid_t.self, BlockedRequest.self), returning: ())
    store.deps.xpc.sendBlockedRequest = sendBlocked.fn

    let flow = FilterFlow(userId: 502)
    await store.send(.flowBlocked(flow, .mock))
    await store.send(.flowBlocked(FilterFlow(userId: 503), .mock)) // <-- different user
    await expect(sendBlocked.calls).toEqual([Both(502, flow.testBlockedReq())])
    store.deps.date = .constant(.epoch + .minutes(5))

    await store.send(.xpc(.receivedAppMessage(.setBlockStreaming(
      enabled: false,
      userId: 502
    )))) {
      $0.blockListeners = [:]
      $0.macappsAliveUntil[502] = .epoch + .minutes(5) + .macappAliveBuffer
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
    let keychain1 = RuleKeychain(keys: [.init(key: .skeleton(scope: .bundleId("com.foo")))])
    let keychain2 = RuleKeychain(keys: [.init(key: .skeleton(scope: .bundleId("com.bar")))])
    let otherUserSuspension = FilterSuspension(scope: .mock, duration: 600)
    let (store, _) = Filter.testStore {
      $0.userKeychains = [
        502: [keychain1],
        503: [keychain2],
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
      $0.userKeychains = [503: [keychain2]]
      $0.suspensions = [503: otherUserSuspension]
      $0.exemptUsers = [501]
    }

    await expect(save.calls).toEqual([.init(
      userKeychains: [503: [keychain2]],
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
      .init(userKeychains: [:], appIdManifest: .init(), exemptUsers: [501, 502]),
      .init(userKeychains: [:], appIdManifest: .init(), exemptUsers: [502]),
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
      $0.macappsAliveUntil[502] = .epoch + .macappAliveBuffer
    }

    store.deps.date = .constant(.epoch + .minutes(2))
    await store.send(.xpc(.receivedAppMessage(.endFilterSuspension(userId: 502)))) {
      $0.suspensions = [503: otherUserSuspension]
      $0.macappsAliveUntil[502] = .epoch + .minutes(2) + .macappAliveBuffer
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

  @MainActor
  func testHeartbeatCleansUpExpiredDowntimePause() async {
    let now = Calendar.current.date(from: DateComponents(hour: 23, minute: 00))!
    let thirtySecondsAgo = now - .seconds(30)
    let fiveMinutesFromNow = now + .minutes(5)
    let (store, _) = Filter.testStore {
      $0.userDowntime = [
        502: Downtime(window: "22:00-05:00", pausedUntil: thirtySecondsAgo), // <-- expired
        503: Downtime(window: "22:00-05:00", pausedUntil: fiveMinutesFromNow), // <-- not expired
        504: Downtime(window: "22:00-05:00", pausedUntil: nil), // <-- no pause
      ]
    }
    store.deps.date = .constant(now)
    await store.send(.heartbeat) {
      $0.userDowntime = [
        502: Downtime(window: "22:00-05:00", pausedUntil: nil), // <- removed
        503: Downtime(window: "22:00-05:00", pausedUntil: fiveMinutesFromNow), // <-- not touched
        504: Downtime(window: "22:00-05:00", pausedUntil: nil), // <-- not touched
      ]
    }
  }

  @MainActor
  func testPauseAndUnpauseDowntime() async {
    let now = Calendar.current.date(from: DateComponents(hour: 23, minute: 00))!
    let (store, _) = Filter.testStore {
      $0.userDowntime = [502: Downtime(window: "22:00-05:00", pausedUntil: nil)]
    }
    store.deps.date = .constant(now)

    await store
      .send(.xpc(.receivedAppMessage(.pauseDowntime(userId: 502, until: now + .minutes(5))))) {
        $0.userDowntime[502] = Downtime(window: "22:00-05:00", pausedUntil: now + .minutes(5))
        $0.macappsAliveUntil[502] = now + .macappAliveBuffer
      }

    store.deps.date = .constant(now + .minutes(2))
    await store.send(.xpc(.receivedAppMessage(.endDowntimePause(userId: 502)))) {
      $0.userDowntime[502] = Downtime(window: "22:00-05:00", pausedUntil: nil)
      $0.macappsAliveUntil[502] = now + .minutes(2) + .macappAliveBuffer
    }
  }

  @MainActor
  func testAliveMessageReceived() async {
    let (store, _) = Filter.testStore()
    await store.send(.xpc(.receivedAppMessage(.macappAlive(userId: 502)))) {
      $0.macappsAliveUntil[502] = .epoch + .macappAliveBuffer
    }
  }

  @MainActor
  func testMacAppsPastAliveBufferCleanedUpInHeartbeat() async {
    let (store, _) = Filter.testStore {
      $0.macappsAliveUntil[502] = .epoch + .macappAliveBuffer
    }
    await store.send(.heartbeat)
    store.deps.date = .constant(.epoch + .macappAliveBuffer - .seconds(1))
    await store.send(.heartbeat)
    store.deps.date = .constant(.epoch + .macappAliveBuffer + .seconds(1))
    await store.send(.heartbeat) { $0.macappsAliveUntil = [:] }
  }

  @MainActor
  func testLogsAppRequests() async {
    let (store, _) = Filter.testStore()
    await store.send(.logAppRequest("com.widget")) {
      $0.logs.bundleIds["com.widget"] = 1
    }
    await store.send(.logAppRequest("com.widget")) {
      $0.logs.bundleIds["com.widget"] = 2
    }
  }

  @MainActor
  func testLogsEventsSendingInHeartbeatWhenThresholdReached() async {
    let (store, _) = Filter.testStore {
      $0.logs.bundleIds["com.widget"] = 498
    }
    store.deps.xpc.sendLogs = { _ in fatalError("not called") }

    let event1 = FilterLogs.Event(id: "1", detail: "whoops")
    await store.send(.logEvent(event1)) {
      $0.logs.events[event1] = 1
    }

    await store.send(.heartbeat) // <-- 499 = not enough logs to send

    let sendLogs = spy(on: FilterLogs.self, returning: ())
    store.deps.xpc.sendLogs = sendLogs.fn

    await store.send(.logEvent(event1)) {
      $0.logs.events[event1] = 2
    }

    await store.send(.heartbeat) { // <-- 500, send logs, clear
      $0.logs.events = [:]
      $0.logs.bundleIds = [:]
    }

    expect(await sendLogs.calls)
      .toEqual([.init(bundleIds: ["com.widget": 498], events: [event1: 2])])
  }

  func testAddFilterLogs() {
    var logs = FilterLogs(bundleIds: [:], events: [:])
    let event1 = FilterLogs.Event(id: "1", detail: "whoops")
    logs.log(event: event1)
    expect(logs.events).toEqual([event1: 1])
    let dupeEvent = FilterLogs.Event(id: "1", detail: "whoops")
    logs.log(event: dupeEvent)
    expect(logs.events).toEqual([event1: 2])
    let newEvent = FilterLogs.Event(id: "2", detail: "whoa")
    logs.log(event: newEvent)
    expect(logs.events).toEqual([event1: 2, newEvent: 1])
    let event3 = FilterLogs.Event(id: "1", detail: nil) // <-- same id, different detail
    logs.log(event: event3)
    expect(logs.events).toEqual([event1: 2, newEvent: 1, event3: 1])
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
    store.deps.filterExtension.version = { "2.5.0" }
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

public extension Date {
  static let epoch = Date(timeIntervalSince1970: 0)
  static let reference = Date(timeIntervalSinceReferenceDate: 0)
}

public extension Double {
  static let macappAliveBuffer = 150.0
}

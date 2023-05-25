import Combine
import ComposableArchitecture
import Core
import MacAppRoute
import TestSupport
import XCTest
import XExpect

@testable import App
@testable import Shared

@MainActor final class AppReducerTests: XCTestCase {
  func testDidFinishLaunching_Exhaustive() async {
    let (store, bgQueue) = AppReducer.testStore(exhaustive: true)

    let filterSetupSpy = ActorIsolated(false)
    store.deps.filterExtension.setup = {
      await filterSetupSpy.setValue(true)
      return .installedButNotRunning
    }

    let tokenSetSpy = ActorIsolated<UUID?>(nil)
    store.deps.api.setUserToken = { await tokenSetSpy.setValue($0) }

    let filterStateSubject = PassthroughSubject<FilterExtensionState, Never>()
    store.deps.filterExtension.stateChanges = { filterStateSubject.eraseToAnyPublisher() }
    store.deps.storage.loadPersistentState = { .mock }

    await store.send(.application(.didFinishLaunching))

    await store.receive(.loadedPersistentState(.mock)) {
      $0.user = .mock
      $0.history.userConnection = .established(welcomeDismissed: true)
    }

    await store.receive(.websocket(.connectedSuccessfully))

    await expect(tokenSetSpy).toEqual(UserData.mock.token)

    await bgQueue.advance(by: .milliseconds(5))
    await expect(filterSetupSpy).toEqual(true)

    await store.receive(.filter(.receivedState(.installedButNotRunning))) {
      $0.filter.extension = .installedButNotRunning
    }

    await bgQueue.advance(by: .milliseconds(5))
    await store.receive(.user(.refreshRules(result: .success(.mock), userInitiated: false))) {
      $0.user?.screenshotsEnabled = true
      $0.user?.keyloggingEnabled = true
      $0.user?.screenshotFrequency = 333
      $0.user?.screenshotSize = 555
    }

    // refreshing rules causes the filter to be rechecked for user key count
    // resulting in a delegate action being sent back to into the system
    await store
      .receive(.adminWindow(.delegate(.healthCheckFilterExtensionState(.installedAndRunning)))) {
        $0.filter.extension = .installedAndRunning
      }

    await store.receive(.adminWindow(.setFilterStatus(.installed(version: "", numUserKeys: 0)))) {
      $0.adminWindow.healthCheck.filterStatus = .installed(version: "", numUserKeys: 0)
    }

    filterStateSubject.send(.notInstalled)
    await store.receive(.filter(.receivedState(.notInstalled))) {
      $0.filter.extension = .notInstalled
    }

    filterStateSubject.send(.installedButNotRunning)
    await store.receive(.filter(.receivedState(.installedButNotRunning))) {
      $0.filter.extension = .installedButNotRunning
    }

    filterStateSubject.send(completion: .finished)
    await store.send(.application(.willTerminate)) // cancel heartbeat
  }

  func testDidFinishLaunching_EstablishesConnectionIfFilterOn() async {
    let (store, bgQueue) = AppReducer.testStore()
    store.deps.storage.loadPersistentState = { nil }
    store.deps.filterExtension.setup = { .installedAndRunning }

    let connectionEstablished = ActorIsolated(false)
    store.deps.filterXpc.establishConnection = {
      await connectionEstablished.setValue(true)
      return .success(())
    }

    await store.send(.application(.didFinishLaunching))
    await bgQueue.advance(by: .milliseconds(5))
    await Task.repeatYield()

    await expect(connectionEstablished).toEqual(true)
  }

  func testDidFinishLaunching_NoPersistentUser() async {
    let (store, _) = AppReducer.testStore()
    store.deps.storage.loadPersistentState = { nil }

    await store.send(.application(.didFinishLaunching))
    await store.receive(.loadedPersistentState(nil))
  }

  func testRefreshRulesInHeartbeat() async {
    let (store, bgQueue) = AppReducer.testStore()
    await store.send(.application(.didFinishLaunching)) // start heartbeat

    let newRules = RefreshRules.Output.mock { $0.screenshotsResolution = 999 }
    store.deps.api.refreshRules = { _ in newRules }

    await bgQueue.advance(by: 60 * 19)
    expect(store.state.user?.screenshotSize).not.toEqual(999)

    await bgQueue.advance(by: 60)
    await store.receive(.user(.refreshRules(result: .success(newRules), userInitiated: false))) {
      $0.user?.screenshotSize = 999
    }
  }

  func testClickingRefreshRules_Success_FilterReachable() async {
    let (store, bgQueue) = AppReducer.testStore()
    let notifications = spyOnNotifications(store)
    await store.send(.application(.didFinishLaunching))

    await bgQueue.advance(by: .milliseconds(5))
    await store.receive(.filter(.receivedState(.installedAndRunning)))

    await store.send(.menuBar(.refreshRulesClicked))
    await expect(notifications).toEqual([.init("Refreshed rules successfully", "")])
  }

  func testClickingRefreshRules_Success_FilterUnreachable() async {
    let (store, bgQueue) = AppReducer.testStore()
    store.deps.filterExtension.setup = { .notInstalled }
    let notifications = spyOnNotifications(store)
    await store.send(.application(.didFinishLaunching))

    await bgQueue.advance(by: .milliseconds(5))
    await store.receive(.filter(.receivedState(.notInstalled)))

    await store.send(.menuBar(.refreshRulesClicked))
    await expect(notifications).toEqual([.init("Refreshed rules successfully", "")])
  }

  func testClickingRefreshRules_FilterError() async {
    let (store, bgQueue) = AppReducer.testStore()
    let notifications = spyOnNotifications(store)
    store.deps.filterXpc.sendUserRules = { _, _ in .failure(.unknownError("printer on fire")) }
    await store.send(.application(.didFinishLaunching))

    await bgQueue.advance(by: .milliseconds(5))
    await store.receive(.filter(.receivedState(.installedAndRunning)))

    await store.send(.menuBar(.refreshRulesClicked))
    await expect(notifications).toEqual([.init(
      "Error refreshing rules",
      "We got updated rules, but there was an error sending them to the filter."
    )])
  }

  func testClickingRefreshRules_ApiError() async {
    let (store, bgQueue) = AppReducer.testStore()
    store.deps.api.refreshRules = { _ in throw TestErr("Oh noes!") }
    let notifications = spyOnNotifications(store)
    await store.send(.application(.didFinishLaunching))

    await bgQueue.advance(by: .milliseconds(5))
    await store.receive(.filter(.receivedState(.installedAndRunning)))

    await store.send(.menuBar(.refreshRulesClicked))
    await expect(notifications).toEqual([.init(
      "Error refreshing rules",
      "Please try again, or contact support if the problem persists."
    )])
  }

  func testHeartbeatClearSuspensionFallback() async {
    let now = Date()
    let (store, scheduler) = AppReducer.testStore {
      $0.filter.currentSuspensionExpiration = now.advanced(by: 60 * 3)
    }

    let time = ControllingNow(starting: now, with: scheduler)
    store.deps.date = time.generator

    await store.send(.application(.didFinishLaunching))

    await time.advance(seconds: 60)
    await store.receive(.heartbeat(.everyMinute))

    await time.advance(seconds: 60)
    await store.receive(.heartbeat(.everyMinute))
    expect(store.state.filter.currentSuspensionExpiration).not.toBeNil()

    await time.advance(seconds: 60)
    await store.receive(.heartbeat(.everyMinute)) {
      $0.filter.currentSuspensionExpiration = nil
    }
  }
}

// helpers

extension AppReducer {
  static func testStore(
    exhaustive: Bool = false,
    reducer: any ReducerOf<AppReducer> = AppReducer(),
    mutateState: @escaping (inout State) -> Void = { _ in }
  ) -> (TestStoreOf<AppReducer>, TestSchedulerOf<DispatchQueue>) {
    var state = State()
    mutateState(&state)
    let store = TestStore(initialState: state, reducer: reducer)
    store.exhaustivity = exhaustive ? .on : .off
    let scheduler = DispatchQueue.test
    store.deps.date = .constant(Date(timeIntervalSince1970: 0))
    store.deps.backgroundQueue = scheduler.eraseToAnyScheduler()
    store.deps.mainQueue = .immediate
    store.deps.storage.loadPersistentState = { .mock }
    store.deps.api.refreshRules = { _ in .mock }
    store.deps.filterExtension.setup = { .installedAndRunning }
    return (store, scheduler)
  }
}

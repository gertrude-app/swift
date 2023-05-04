import Combine
import ComposableArchitecture
import MacAppRoute
import TestSupport
import XCTest
import XExpect

@testable import App
@testable import Models

@MainActor final class AppReducerTests: XCTestCase {
  func testDidFinishLaunching_Exhaustive() async {
    let (store, _) = AppReducer.testStore(exhaustive: true)

    let filterSetupSpy = ActorIsolated(false)
    store.deps.filterExtension.setup = {
      await filterSetupSpy.setValue(true)
      return .off
    }

    let tokenSetSpy = ActorIsolated<User.Token?>(nil)
    store.deps.api.setUserToken = { await tokenSetSpy.setValue($0) }

    let filterStateSubject = PassthroughSubject<FilterState, Never>()
    store.deps.filterExtension.stateChanges = { filterStateSubject.eraseToAnyPublisher() }
    store.deps.storage.loadPersistentState = { .init(user: .mock) }

    await store.send(.application(.didFinishLaunching))

    await store.receive(.loadedPersistentState(.init(user: .mock))) {
      $0.user = .mock
      $0.history.userConnection = .established(welcomeDismissed: true)
    }

    await expect(tokenSetSpy).toEqual(User.mock.token)
    await expect(filterSetupSpy).toEqual(true)

    await store.receive(.filter(.receivedState(.off))) {
      $0.filter = .off
    }

    await store.receive(.user(.refreshRules(result: .success(.mock), userInitiated: false))) {
      $0.user?.screenshotFrequency = 333
      $0.user?.screenshotSize = 555
    }

    await store.receive(.adminWindow(.setFilterStatus(.installed(version: "", numUserKeys: 0)))) {
      $0.adminWindow.healthCheck.filterStatus = .installed(version: "", numUserKeys: 0)
    }

    filterStateSubject.send(.on)
    await store.receive(.filter(.receivedState(.on))) {
      $0.filter = .on
    }

    filterStateSubject.send(.off)
    await store.receive(.filter(.receivedState(.off))) {
      $0.filter = .off
    }

    filterStateSubject.send(completion: .finished)
    await store.send(.application(.willTerminate)) // cancel heartbeat
  }

  func testDidFinishLaunching_EstablishesConnectionIfFilterOn() async {
    let (store, _) = AppReducer.testStore()
    store.deps.storage.loadPersistentState = { nil }
    store.deps.filterExtension.setup = { .on }

    let connectionEstablished = ActorIsolated(false)
    store.deps.filterXpc.establishConnection = {
      await connectionEstablished.setValue(true)
      return .success(())
    }

    await store.send(.application(.didFinishLaunching))

    await expect(connectionEstablished).toEqual(true)
  }

  func testDidFinishLaunching_NoPersistentUser() async {
    let (store, _) = AppReducer.testStore()
    store.deps.storage.loadPersistentState = { nil }

    await store.send(.application(.didFinishLaunching))
    await store.receive(.loadedPersistentState(nil))
  }

  func testRefreshRulesInHeartbeat() async {
    let (store, time) = AppReducer.testStore()
    await store.send(.application(.didFinishLaunching)) // start heartbeat

    let newRules = RefreshRules.Output.mock { $0.screenshotsResolution = 999 }
    store.deps.api.refreshRules = { _ in newRules }

    await time.advance(by: 60 * 19)
    expect(store.state.user?.screenshotSize).not.toEqual(999)

    await time.advance(by: 60)
    await store.receive(.user(.refreshRules(result: .success(newRules), userInitiated: false))) {
      $0.user?.screenshotSize = 999
    }
  }

  func testClickingRefreshRules_Success_FilterReachable() async {
    let (store, _) = AppReducer.testStore()
    let notifications = spyOnNotifications(store)
    await store.send(.application(.didFinishLaunching))
    await store.receive(.filter(.receivedState(.on)))

    await store.send(.menuBar(.refreshRulesClicked))
    await expect(notifications).toEqual([.init("Refreshed rules successfully", "")])
  }

  func testClickingRefreshRules_Success_FilterUnreachable() async {
    let (store, _) = AppReducer.testStore()
    store.deps.filterExtension.setup = { .notInstalled }
    let notifications = spyOnNotifications(store)
    await store.send(.application(.didFinishLaunching))
    await store.receive(.filter(.receivedState(.notInstalled)))

    await store.send(.menuBar(.refreshRulesClicked))
    await expect(notifications).toEqual([.init("Refreshed rules successfully", "")])
  }

  func testClickingRefreshRules_FilterError() async {
    let (store, _) = AppReducer.testStore()
    let notifications = spyOnNotifications(store)
    store.deps.filterXpc.sendUserRules = { _, _ in .failure(.unknownError("printer on fire")) }
    await store.send(.application(.didFinishLaunching))
    await store.receive(.filter(.receivedState(.on)))

    await store.send(.menuBar(.refreshRulesClicked))
    await expect(notifications).toEqual([.init(
      "Error refreshing rules",
      "We got updated rules, but there was an error sending them to the filter."
    )])
  }

  func testClickingRefreshRules_ApiError() async {
    let (store, _) = AppReducer.testStore()
    store.deps.api.refreshRules = { _ in throw TestErr("Oh noes!") }
    let notifications = spyOnNotifications(store)
    await store.send(.application(.didFinishLaunching))
    await store.receive(.filter(.receivedState(.on)))

    await store.send(.menuBar(.refreshRulesClicked))
    await expect(notifications).toEqual([.init(
      "Error refreshing rules",
      "Please try again, or contact support if the problem persists."
    )])
  }
}

// helpers

extension AppReducer {
  static func testStore(exhaustive: Bool = false)
    -> (TestStoreOf<AppReducer>, TestSchedulerOf<DispatchQueue>) {
    let store = TestStore(initialState: State(), reducer: AppReducer())
    store.exhaustivity = exhaustive ? .on : .off
    let scheduler = DispatchQueue.test
    store.deps.backgroundQueue = scheduler.eraseToAnyScheduler()
    store.deps.mainQueue = .immediate
    store.deps.storage.loadPersistentState = { .init(user: .mock) }
    store.deps.api.refreshRules = { _ in .mock }
    store.deps.filterExtension.setup = { .on }
    return (store, scheduler)
  }
}

import Combine
import ComposableArchitecture
import MacAppRoute
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

    await store.receive(.user(.refreshRules(.success(.mock)))) {
      $0.user?.screenshotFrequency = 333
      $0.user?.screenshotSize = 555
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
    await store.receive(.user(.refreshRules(.success(newRules)))) {
      $0.user?.screenshotSize = 999
    }
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
    return (store, scheduler)
  }
}

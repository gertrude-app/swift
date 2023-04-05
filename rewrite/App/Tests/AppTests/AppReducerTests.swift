import Combine
import ComposableArchitecture
import MacAppRoute
import XCTest
import XExpect

@testable import App
@testable import Models

extension TestStore {
  var deps: DependencyValues {
    get { dependencies }
    set { dependencies = newValue }
  }
}

@MainActor final class AppReducerTests: XCTestCase {
  func testDidFinishLaunching_Exhaustive() async {
    let store = TestStore(initialState: AppReducer.State(), reducer: AppReducer())

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
    store.deps.mainQueue = .immediate

    await store.send(.delegate(.didFinishLaunching))

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
  }

  func testDidFinishLaunching_EstablishesConnectionIfFilterOn() async {
    let store = TestStore(initialState: AppReducer.State(), reducer: AppReducer())
    store.exhaustivity = .off
    store.deps.storage.loadPersistentState = { nil }
    store.deps.filterExtension.setup = { .on }
    store.deps.mainQueue = .immediate

    let didEstablishConnection = ActorIsolated(false)
    store.deps.filterXpc.establishConnection = {
      await didEstablishConnection.setValue(true)
      return .success(())
    }

    await store.send(.delegate(.didFinishLaunching))

    await expect(didEstablishConnection).toEqual(true)
  }

  func testDidFinishLaunching_NoPersistentUser() async {
    let store = TestStore(initialState: AppReducer.State(), reducer: AppReducer())
    store.exhaustivity = .off
    store.deps.storage.loadPersistentState = { nil }
    store.deps.mainQueue = .immediate

    await store.send(.delegate(.didFinishLaunching))
    await store.receive(.loadedPersistentState(nil))
  }
}

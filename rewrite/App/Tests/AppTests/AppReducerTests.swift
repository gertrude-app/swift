import Combine
import ComposableArchitecture
import XCTest

@testable import App
@testable import Models

extension TestStore {
  var deps: DependencyValues {
    get { dependencies }
    set { dependencies = newValue }
  }
}

@MainActor final class AppReducerTests: XCTestCase {
  func testDidFinishLaunching() async {
    let store = TestStore(initialState: AppReducer.State(), reducer: AppReducer())

    let didSetupFilter = ActorIsolated(false)
    store.deps.filterExtension.setup = {
      await didSetupFilter.setValue(true)
      return .off
    }

    let filterStateSubject = PassthroughSubject<FilterState, Never>()
    store.deps.filterExtension.stateChanges = { filterStateSubject.eraseToAnyPublisher() }
    store.deps.storage.loadPersistentState = { .init(user: .mock) }
    store.deps.mainQueue = .immediate

    await store.send(.delegate(.didFinishLaunching))

    await store.receive(.loadedPersistentState(.init(user: .mock))) {
      $0.user = .mock
      $0.history.userConnection = .established(welcomeDismissed: true)
    }

    let setupRan = await didSetupFilter.value
    XCTAssertTrue(setupRan)

    await store.receive(.filter(.receivedState(.off))) {
      $0.filter = .off
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

    let establishRan = await didEstablishConnection.value
    XCTAssertTrue(establishRan)
  }

  func testDidFinishLaunching_NoPersistentUser() async {
    let store = TestStore(initialState: AppReducer.State(), reducer: AppReducer())
    store.exhaustivity = .off
    store.deps.storage.loadPersistentState = { nil }
    store.deps.mainQueue = .immediate

    await store.send(.delegate(.didFinishLaunching))
    await store.receive(.loadedPersistentState(nil)) {
      $0.user = nil
      $0.history.userConnection = .notConnected
    }
  }
}

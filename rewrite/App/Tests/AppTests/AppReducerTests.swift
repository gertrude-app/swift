import Combine
import ComposableArchitecture
import XCTest

@testable import App
@testable import Models

@MainActor final class AppReducerTests: XCTestCase {
  func testDidFinishLaunching() async {
    let store = TestStore(initialState: AppReducer.State(), reducer: AppReducer())

    let didSetupFilter = ActorIsolated(false)
    store.dependencies.filter.setup = {
      await didSetupFilter.setValue(true)
      return .off
    }

    let filterStateSubject = PassthroughSubject<FilterState, Never>()
    store.dependencies.filter.changes = { filterStateSubject.eraseToAnyPublisher() }
    store.dependencies.storage.loadPersistentState = { .init(user: .mock) }

    await store.send(.delegate(.didFinishLaunching))

    let setupRan = await didSetupFilter.value
    XCTAssertTrue(setupRan)

    await store.receive(.filter(.receivedState(.off))) {
      $0.filter = .off
    }

    await store.receive(.loadedPersistentState(.init(user: .mock))) {
      $0.user = .mock
      $0.history.userConnection = .established(welcomeDismissed: true)
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

  func testDidFinishLaunching_NoPersistentUser() async {
    let store = TestStore(initialState: AppReducer.State(), reducer: AppReducer())
    store.exhaustivity = .off
    store.dependencies.storage.loadPersistentState = { nil }
    await store.send(.delegate(.didFinishLaunching))
    await store.receive(.loadedPersistentState(nil)) {
      $0.user = nil
      $0.history.userConnection = .notConnected
    }
  }
}

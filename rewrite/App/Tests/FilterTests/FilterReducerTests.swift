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

    let key = FilterKey(id: .init(), key: .skeleton(scope: .bundleId("com.foo")))
    let manifest = AppIdManifest(apps: ["Lol": ["com.lol"]])
    let message = XPCEvent.Filter
      .receivedAppMessage(.userRules(userId: 502, keys: [key], manifest: manifest))

    subject.send(message)

    await store.receive(.receivedXpcEvent(message)) {
      $0.userKeys[502] = [key]
      $0.appIdManifest = manifest
    }

    subject.send(completion: .finished)
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
    return (store, scheduler)
  }
}

import ComposableArchitecture
import Dependencies
import Foundation
import Models
import XExpect

@testable import App

func expect<T: Equatable>(
  _ isolated: ActorIsolated<T>,
  file: StaticString = #filePath,
  line: UInt = #line
) async -> EquatableExpectation<T> {
  EquatableExpectation(value: await isolated.value, file: file, line: line)
}

func expect<T: Equatable>(
  _ isolated: LockIsolated<T>,
  file: StaticString = #filePath,
  line: UInt = #line
) -> EquatableExpectation<T> {
  EquatableExpectation(value: isolated.value, file: file, line: line)
}

struct TestErr: Equatable, Error, LocalizedError {
  let msg: String
  var errorDescription: String? { msg }
  init(_ msg: String) { self.msg = msg }
}

extension TestStore {
  var deps: DependencyValues {
    get { dependencies }
    set { dependencies = newValue }
  }
}

func spyOnNotifications(_ store: TestStoreOf<AppReducer>) -> ActorIsolated<[TestNotification]> {
  let spy = ActorIsolated<[TestNotification]>([])
  store.deps.device.showNotification = { title, body in
    var value = await spy.value
    value.append(TestNotification(title, body))
    let replace = value
    await spy.setValue(replace)
  }
  return spy
}

struct TestNotification: Equatable {
  var title: String
  var body: String
  init(_ title: String, _ body: String) {
    self.title = title
    self.body = body
  }
}

typealias TestStoreOf<R: Reducer> = TestStore<R.State, R.Action, R.State, R.Action, Void>

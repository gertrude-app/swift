import ComposableArchitecture
import Dependencies
import Foundation
import Models
import XExpect

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

typealias TestStoreOf<R: Reducer> = TestStore<R.State, R.Action, R.State, R.Action, Void>

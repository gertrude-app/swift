import ComposableArchitecture
import Foundation
import XExpect

public typealias TestStoreOf<R: Reducer> = TestStore<R.State, R.Action, R.State, R.Action, Void>

public func expect<T: Equatable>(
  _ isolated: ActorIsolated<T>,
  file: StaticString = #filePath,
  line: UInt = #line
) async -> EquatableExpectation<T> {
  EquatableExpectation(value: await isolated.value, file: file, line: line)
}

public func expect<T: Equatable>(
  _ isolated: LockIsolated<T>,
  file: StaticString = #filePath,
  line: UInt = #line
) -> EquatableExpectation<T> {
  EquatableExpectation(value: isolated.value, file: file, line: line)
}

public struct TestErr: Equatable, Error, LocalizedError {
  public let msg: String
  public var errorDescription: String? { msg }
  public init(_ msg: String) { self.msg = msg }
}

public extension TestStore {
  var deps: DependencyValues {
    get { dependencies }
    set { dependencies = newValue }
  }
}

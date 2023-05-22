import ComposableArchitecture
import Foundation
import XExpect

public extension Task where Success == Never, Failure == Never {
  static func repeatYield(count: Int = 10) async {
    for _ in 1 ... count {
      await Task<Void, Never>.detached(priority: .background) { await Task.yield() }.value
    }
  }
}

public typealias TestStoreOf<R: Reducer> = TestStore<R.State, R.Action, R.State, R.Action, Void>

public extension DateGenerator {
  static func advancingOneMinute(starting: Date = Date()) -> DateGenerator {
    let minutesPassed = LockIsolated(0)
    return .init {
      let numMinutes = minutesPassed.value + 1
      minutesPassed.setValue(numMinutes)
      return starting.advanced(by: 60 * Double(numMinutes))
    }
  }
}

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

public extension ActorIsolated where Value: RangeReplaceableCollection {
  func append(_ newElement: Value.Element) async {
    value.append(newElement)
  }
}

// if/when tuples become Sendable, this (and `Three`) can be removed
public struct Both<A, B> {
  public var a: A
  public var b: B
  public init(_ a: A, _ b: B) {
    self.a = a
    self.b = b
  }
}

public struct Three<A, B, C> {
  public var a: A
  public var b: B
  public var c: C
  public init(_ a: A, _ b: B, _ c: C) {
    self.a = a
    self.b = b
    self.c = c
  }
}

extension Both: Sendable where A: Sendable, B: Sendable {}
extension Both: Equatable where A: Equatable, B: Equatable {}
extension Three: Sendable where A: Sendable, B: Sendable, C: Sendable {}
extension Three: Equatable where A: Equatable, B: Equatable, C: Equatable {}

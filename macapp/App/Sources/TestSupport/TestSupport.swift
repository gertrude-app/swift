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

public typealias TestStoreOf<R: Reducer> = TestStore<R.State, R.Action>

public extension UUID {
  static let deadbeef = UUID(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef")!
  static let zeros = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
  static let ones = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
  static let twos = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

  init(_ intValue: Int) {
    self.init(uuidString: "00000000-0000-0000-0000-\(String(format: "%012x", intValue))")!
  }
}

extension UUID: @retroactive ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self.init(value)
  }
}

public extension Date {
  static let epoch = Date(timeIntervalSince1970: 0)
}

public struct ControllingNow {
  public let generator: DateGenerator
  private let elapsed: LockIsolated<Int>
  private let scheduler: TestSchedulerOf<DispatchQueue>?

  internal init(
    generator: DateGenerator,
    elapsed: LockIsolated<Int>,
    scheduler: TestSchedulerOf<DispatchQueue>? = nil
  ) {
    self.generator = generator
    self.elapsed = elapsed
    self.scheduler = scheduler
  }

  public init(
    starting start: Date = Date(),
    with scheduler: TestSchedulerOf<DispatchQueue>? = nil
  ) {
    let elapsed = LockIsolated<Int>(0)
    self.init(
      generator: .init {
        start.advanced(by: Double(elapsed.value))
      },
      elapsed: elapsed,
      scheduler: scheduler
    )
  }

  /// advance the time, but not the scheduler.
  /// this simulates when the computer is asleep, when timers spun up
  /// by mainQueue.sleep(for:) are suspended (because i can't use ContinuousClock)
  /// but real wall-clock time is advancing
  public func simulateComputerSleep(seconds advance: Int) {
    let current = self.elapsed.value
    self.elapsed.setValue(current + advance)
  }

  public func advance(seconds advance: Int) async {
    let current = self.elapsed.value
    self.elapsed.setValue(current + advance)
    if let scheduler = scheduler {
      await scheduler.advance(by: .seconds(advance))
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
  public var errorDescription: String? { self.msg }
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

public extension LockIsolated where Value: RangeReplaceableCollection {
  func append(_ newElement: Value.Element) {
    withValue { $0.append(newElement) }
  }
}

public let IS_CI = ProcessInfo.processInfo.environment["CI"] != nil

// if/when tuples become Sendable, this, `Three`, and `Four` can be removed
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

public struct Four<A, B, C, D> {
  public var a: A
  public var b: B
  public var c: C
  public var d: D
  public init(_ a: A, _ b: B, _ c: C, _ d: D) {
    self.a = a
    self.b = b
    self.c = c
    self.d = d
  }
}

extension Both: Sendable where A: Sendable, B: Sendable {}
extension Both: Equatable where A: Equatable, B: Equatable {}
extension Three: Sendable where A: Sendable, B: Sendable, C: Sendable {}
extension Three: Equatable where A: Equatable, B: Equatable, C: Equatable {}
extension Four: Sendable where A: Sendable, B: Sendable, C: Sendable, D: Sendable {}
extension Four: Equatable where A: Equatable, B: Equatable, C: Equatable, D: Equatable {}

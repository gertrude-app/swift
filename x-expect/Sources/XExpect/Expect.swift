import CustomDump
import XCTest

public struct CollectionExpectation<T: Collection> {
  let collection: T
  var negated = false
  let file: StaticString
  let line: UInt

  public init(collection: T, negated: Bool = false, file: StaticString, line: UInt) {
    self.collection = collection
    self.negated = negated
    self.file = file
    self.line = line
  }

  public var not: Self {
    Self(collection: self.collection, negated: true, file: #file, line: #line)
  }

  public func toHaveCount(_ count: Int) {
    if self.negated {
      XCTAssertNotEqual(self.collection.count, count, file: self.file, line: self.line)
    } else {
      XCTAssertNoDifference(self.collection.count, count, file: self.file, line: self.line)
    }
  }

  public func toBeEmpty() {
    if self.negated {
      XCTAssertFalse(self.collection.isEmpty, file: self.file, line: self.line)
    } else {
      XCTAssertTrue(self.collection.isEmpty, file: self.file, line: self.line)
    }
  }
}

public extension CollectionExpectation where T: Equatable {
  func toEqual(_ expected: T) {
    if self.negated {
      XCTAssertNotEqual(self.collection, expected, file: self.file, line: self.line)
    } else {
      XCTAssertNoDifference(self.collection, expected, file: self.file, line: self.line)
    }
  }
}

public struct ErrorExpectation<T> {
  let fn: () async throws -> T
  let file: StaticString
  let line: UInt

  public init(fn: @escaping () async throws -> T, file: StaticString, line: UInt) {
    self.fn = fn
    self.file = file
    self.line = line
  }

  public func toContain(_ substring: String) async throws {
    do {
      _ = try await self.fn()
      XCTFail("Expected error, got none", file: self.file, line: self.line)
    } catch {
      expect("\(error)", file: self.file, line: self.line).toContain(substring)
    }
  }
}

public struct EquatableExpectation<T: Equatable> {
  let value: T
  var negated = false
  let file: StaticString
  let line: UInt

  public init(value: T, negated: Bool = false, file: StaticString, line: UInt) {
    self.value = value
    self.negated = negated
    self.file = file
    self.line = line
  }

  public var not: Self {
    Self(value: self.value, negated: true, file: #file, line: #line)
  }

  public func toEqual(_ other: T) {
    if self.negated {
      XCTAssertNotEqual(self.value, other, file: self.file, line: self.line)
    } else {
      XCTAssertNoDifference(self.value, other, file: self.file, line: self.line)
    }
  }
}

public struct EquatableOptionalExpectation<T: Equatable> {
  let value: T?
  var negated = false
  let file: StaticString
  let line: UInt

  public init(value: T? = nil, negated: Bool = false, file: StaticString, line: UInt) {
    self.value = value
    self.negated = negated
    self.file = file
    self.line = line
  }

  public var not: Self {
    Self(value: self.value, negated: true, file: #file, line: #line)
  }

  public func toEqual(_ other: T) {
    if self.negated {
      XCTAssertNotEqual(self.value, other, file: self.file, line: self.line)
    } else {
      XCTAssertNoDifference(self.value, other, file: self.file, line: self.line)
    }
  }

  public func toBeNil() {
    if self.negated {
      XCTAssertNotNil(self.value, file: self.file, line: self.line)
    } else {
      XCTAssertNil(self.value, file: self.file, line: self.line)
    }
  }
}

public struct ResultExpectation<Success, Failure: Swift.Error> {
  let result: Result<Success, Failure>
  let file: StaticString
  let line: UInt

  public init(result: Result<Success, Failure>, file: StaticString, line: UInt) {
    self.result = result
    self.file = file
    self.line = line
  }

  public func toBeError(containing substring: String) {
    switch self.result {
    case .success(let value):
      XCTFail("Expected error, got success: \(value)", file: self.file, line: self.line)
    case .failure(let error):
      XCTAssert(
        "\(error)".contains(substring),
        "Expected error `\(error)` to contain `\(substring)`",
        file: self.file,
        line: self.line
      )
    }
  }
}

public struct OptionalExpectation {
  let value: Any?
  let file: StaticString
  let line: UInt

  public init(value: Any? = nil, file: StaticString, line: UInt) {
    self.value = value
    self.file = file
    self.line = line
  }

  public func toBeNil() {
    XCTAssertNil(self.value, file: self.file, line: self.line)
  }
}

public struct StringExpectation {
  let value: String
  var negated = false
  let file: StaticString
  let line: UInt

  public init(value: String, negated: Bool = false, file: StaticString, line: UInt) {
    self.value = value
    self.negated = negated
    self.file = file
    self.line = line
  }

  public var not: Self {
    Self(value: self.value, negated: true, file: #file, line: #line)
  }

  public func toBe(_ other: String) {
    if self.negated {
      XCTAssertNotEqual(self.value, other, file: self.file, line: self.line)
    } else {
      XCTAssertNoDifference(self.value, other, file: self.file, line: self.line)
    }
  }

  public func toContain(_ substring: String) {
    if !self.negated {
      XCTAssert(
        self.value.contains(substring),
        "Expected `\(self.value)` to contain `\(substring)`",
        file: self.file,
        line: self.line
      )
    } else {
      XCTAssert(
        !self.value.contains(substring),
        "Expected `\(self.value)` NOT to contain `\(substring)`",
        file: self.file,
        line: self.line
      )
    }
  }
}

public struct BoolExpectation {
  let value: Bool
  let file: StaticString
  let line: UInt

  public init(value: Bool, file: StaticString, line: UInt) {
    self.value = value
    self.file = file
    self.line = line
  }

  public func toBeTrue() {
    XCTAssert(self.value, file: self.file, line: self.line)
  }

  public func toBeFalse() {
    XCTAssert(!self.value, file: self.file, line: self.line)
  }
}

public func expect(
  _ value: Bool,
  file: StaticString = #filePath,
  line: UInt = #line
) -> BoolExpectation {
  BoolExpectation(value: value, file: file, line: line)
}

public func expect(
  _ value: String,
  file: StaticString = #filePath,
  line: UInt = #line
) -> StringExpectation {
  StringExpectation(value: value, file: file, line: line)
}

@_disfavoredOverload
public func expect<T: Equatable>(
  _ value: T,
  file: StaticString = #filePath,
  line: UInt = #line
) -> EquatableExpectation<T> {
  EquatableExpectation(value: value, file: file, line: line)
}

@_disfavoredOverload
public func expect<T: Equatable>(
  _ value: T?,
  file: StaticString = #filePath,
  line: UInt = #line
) -> EquatableOptionalExpectation<T> {
  EquatableOptionalExpectation(value: value, file: file, line: line)
}

public func expect<T>(
  _ value: T?,
  file: StaticString = #filePath,
  line: UInt = #line
) -> OptionalExpectation {
  OptionalExpectation(value: value, file: file, line: line)
}

public func expect<C: Collection>(
  _ collection: C,
  file: StaticString = #filePath,
  line: UInt = #line
) -> CollectionExpectation<C> {
  CollectionExpectation(collection: collection, file: file, line: line)
}

public func expect<S, F: Error>(
  _ result: Result<S, F>,
  file: StaticString = #filePath,
  line: UInt = #line
) -> ResultExpectation<S, F> {
  ResultExpectation(result: result, file: file, line: line)
}

public func expectErrorFrom<T>(
  file: StaticString = #filePath,
  line: UInt = #line,
  fn: @escaping () async throws -> T
) -> ErrorExpectation<T> {
  ErrorExpectation(fn: fn, file: file, line: line)
}

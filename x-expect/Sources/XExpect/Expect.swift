import XCTest

public struct CollectionExpectation<T: Collection> {
  let collection: T
  var negated = false
  let file: StaticString
  let line: UInt

  public var not: Self {
    Self(collection: collection, negated: true, file: #file, line: #line)
  }

  public func toHaveCount(_ count: Int) {
    if negated {
      XCTAssertNotEqual(collection.count, count, file: file, line: line)
    } else {
      XCTAssertEqual(collection.count, count, file: file, line: line)
    }
  }

  public func toBeEmpty() {
    if negated {
      XCTAssertFalse(collection.isEmpty, file: file, line: line)
    } else {
      XCTAssertTrue(collection.isEmpty, file: file, line: line)
    }
  }
}

public struct ErrorExpectation<T> {
  let fn: () async throws -> T
  let file: StaticString
  let line: UInt

  public func toContain(_ substring: String) async throws {
    do {
      _ = try await fn()
      XCTFail("Expected error, got none", file: file, line: line)
    } catch {
      expect("\(error)", file: file, line: line).toContain(substring)
    }
  }
}

public struct EquatableExpectation<T: Equatable> {
  let value: T
  var negated = false
  let file: StaticString
  let line: UInt

  public var not: Self {
    Self(value: value, negated: true, file: #file, line: #line)
  }

  public func toEqual(_ other: T) {
    if negated {
      XCTAssertNotEqual(value, other, file: file, line: line)
    } else {
      XCTAssertEqual(value, other, file: file, line: line)
    }
  }
}

public struct EquatableOptionalExpectation<T: Equatable> {
  let value: T?
  var negated = false
  let file: StaticString
  let line: UInt

  public var not: Self {
    Self(value: value, negated: true, file: #file, line: #line)
  }

  public func toEqual(_ other: T) {
    if negated {
      XCTAssertNotEqual(value, other, file: file, line: line)
    } else {
      XCTAssertEqual(value, other, file: file, line: line)
    }
  }

  public func toBeNil() {
    if negated {
      XCTAssertNotNil(value, file: file, line: line)
    } else {
      XCTAssertNil(value, file: file, line: line)
    }
  }
}

public struct ResultExpectation<Success, Failure: Swift.Error> {
  let result: Result<Success, Failure>
  let file: StaticString
  let line: UInt

  public func toBeError(containing substring: String) {
    switch result {
    case .success(let value):
      XCTFail("Expected error, got success: \(value)", file: file, line: line)
    case .failure(let error):
      XCTAssert(
        "\(error)".contains(substring),
        "Expected error `\(error)` to contain `\(substring)`",
        file: file,
        line: line
      )
    }
  }
}

public struct OptionalExpectation {
  let value: Any?
  let file: StaticString
  let line: UInt

  public func toBeNil() {
    XCTAssertNil(value, file: file, line: line)
  }
}

public struct StringExpectation {
  let value: String
  var negated = false
  let file: StaticString
  let line: UInt

  public var not: Self {
    Self(value: value, negated: true, file: #file, line: #line)
  }

  public func toBe(_ other: String) {
    if negated {
      XCTAssertNotEqual(value, other, file: file, line: line)
    } else {
      XCTAssertEqual(value, other, file: file, line: line)
    }
  }

  public func toContain(_ substring: String) {
    if !negated {
      XCTAssert(
        value.contains(substring),
        "Expected `\(value)` to contain `\(substring)`",
        file: file,
        line: line
      )
    } else {
      XCTAssert(
        !value.contains(substring),
        "Expected `\(value)` NOT to contain `\(substring)`",
        file: file,
        line: line
      )
    }
  }
}

public struct BoolExpectation {
  let value: Bool
  let file: StaticString
  let line: UInt

  public func toBeTrue() {
    XCTAssert(value, file: file, line: line)
  }

  public func toBeFalse() {
    XCTAssert(!value, file: file, line: line)
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

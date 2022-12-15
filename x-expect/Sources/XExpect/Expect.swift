import XCTest

public struct ErrorExpectation<T> {
  public let fn: () async throws -> T
  public let file: StaticString
  public let line: UInt

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
  public let value: T
  public let file: StaticString
  public let line: UInt

  public func toEqual(_ other: T) {
    XCTAssertEqual(value, other, file: file, line: line)
  }

  public func toBeNil() {
    XCTAssertNil(value, file: file, line: line)
  }

  public func toNotBeNil() {
    XCTAssertNotNil(value, file: file, line: line)
  }
}

public struct ResultExpectation<Success, Failure: Swift.Error> {
  public let result: Result<Success, Failure>
  public let file: StaticString
  public let line: UInt

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
  public let value: Any?
  public let file: StaticString
  public let line: UInt

  public func toBeNil() {
    XCTAssertNil(value, file: file, line: line)
  }
}

public struct StringExpectation {
  public let value: String
  public let file: StaticString
  public let line: UInt

  public func toBe(_ other: String) {
    XCTAssertEqual(value, other, file: file, line: line)
  }

  public func toContain(_ substring: String) {
    XCTAssert(
      value.contains(substring),
      "Expected `\(value)` to contain `\(substring)`",
      file: file,
      line: line
    )
  }
}

public struct BoolExpectation {
  public let value: Bool
  public let file: StaticString
  public let line: UInt

  public func toBeTrue() {
    XCTAssert(value, file: file, line: line)
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

public func expect<T>(
  _ value: T?,
  file: StaticString = #filePath,
  line: UInt = #line
) -> OptionalExpectation {
  OptionalExpectation(value: value, file: file, line: line)
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

import XCTest

struct ErrorExpectation<T> {
  let fn: () async throws -> T
  let file: StaticString
  let line: UInt

  func toContain(_ substring: String) async throws {
    do {
      _ = try await fn()
      XCTFail("Expected error, got none", file: file, line: line)
    } catch {
      expect("\(error)", file: file, line: line).toContain(substring)
    }
  }
}

struct EquatableExpectation<T: Equatable> {
  let value: T
  let file: StaticString
  let line: UInt

  func toEqual(_ other: T) {
    XCTAssertEqual(value, other, file: file, line: line)
  }

  func toBeNil() {
    XCTAssertNil(value, file: file, line: line)
  }
}

struct ResultExpectation<Success, Failure: Swift.Error> {
  let result: Result<Success, Failure>
  let file: StaticString
  let line: UInt

  func toBeError(containing substring: String) {
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

struct OptionalExpectation {
  let value: Any?
  let file: StaticString
  let line: UInt

  func toBeNil() {
    XCTAssertNil(value, file: file, line: line)
  }
}

struct StringExpectation {
  let value: String
  let file: StaticString
  let line: UInt

  func toBe(_ other: String) {
    XCTAssertEqual(value, other, file: file, line: line)
  }

  func toContain(_ substring: String) {
    XCTAssert(
      value.contains(substring),
      "Expected `\(value)` to contain `\(substring)`",
      file: file,
      line: line
    )
  }
}

struct BoolExpectation {
  let value: Bool
  let file: StaticString
  let line: UInt

  func toBeTrue() {
    XCTAssert(value, file: file, line: line)
  }
}

func expect(
  _ value: Bool,
  file: StaticString = #filePath,
  line: UInt = #line
) -> BoolExpectation {
  BoolExpectation(value: value, file: file, line: line)
}

func expect(
  _ value: String,
  file: StaticString = #filePath,
  line: UInt = #line
) -> StringExpectation {
  StringExpectation(value: value, file: file, line: line)
}

@_disfavoredOverload
func expect<T: Equatable>(
  _ value: T,
  file: StaticString = #filePath,
  line: UInt = #line
) -> EquatableExpectation<T> {
  EquatableExpectation(value: value, file: file, line: line)
}

func expect<T>(
  _ value: T?,
  file: StaticString = #filePath,
  line: UInt = #line
) -> OptionalExpectation {
  OptionalExpectation(value: value, file: file, line: line)
}

func expect<S, F: Error>(
  _ result: Result<S, F>,
  file: StaticString = #filePath,
  line: UInt = #line
) -> ResultExpectation<S, F> {
  ResultExpectation(result: result, file: file, line: line)
}

func expectErrorFrom<T>(
  file: StaticString = #filePath,
  line: UInt = #line,
  fn: @escaping () async throws -> T
) -> ErrorExpectation<T> {
  ErrorExpectation(fn: fn, file: file, line: line)
}

import XCTest
import XExpect

@testable import TypeScriptInterop

final class NodeTests: XCTestCase {

  func testParseNodePrimitive() throws {
    expect(try Node(from: String.self)).toEqual(.primitive(.string))
    expect(try Node(from: Int.self)).toEqual(.primitive(.number(.int)))
    expect(try Node(from: Bool.self)).toEqual(.primitive(.boolean))
  }

  func testParseArray() throws {
    expect(try Node(from: [String].self)).toEqual(.array(.primitive(.string), .string))
    expect(try Node(from: [Int].self)).toEqual(.array(.primitive(.number(.int)), .int))
    expect(try Node(from: [Bool].self)).toEqual(.array(.primitive(.boolean), .bool))
    expect(try Node(from: [[Bool]].self))
      .toEqual(.array(.array(.primitive(.boolean), .bool), .init([Bool].self)))

    struct Foo { var bar: Int }
    expect(try Node(from: [Foo].self)).toEqual(.array(.object([
      .init(name: "bar", value: .primitive(.number(.int))),
    ], .init(Foo.self)), .init(Foo.self)))
  }

  func testParseDictionary() async throws {
    expect(try Node(from: [String: String].self)).toEqual(.record(.primitive(.string)))
    expect(try Node(from: [String: Int].self)).toEqual(.record(.primitive(.number(.int))))

    struct Foo { var bar: Int }
    expect(try Node(from: [String: Foo].self)).toEqual(.record(.object([
      .init(name: "bar", value: .primitive(.number(.int))),
    ], .init(Foo.self))))

    try await expectErrorFrom {
      try Node(from: [Int: String].self)
    }.toContain("non-string keys")
  }

  func testEnumWithMultipleUnnamedValuesThrows() async throws {
    enum NotGoodForTs {
      case a
      case b(Int, Int)
    }

    try await expectErrorFrom {
      try Node(from: NotGoodForTs.self)
    }.toContain("unnamed tuple members")
  }

  func testUnrepresentableTupleThrows() async throws {
    try await expectErrorFrom {
      try Node(from: (Int?, String).self)
    }.toContain("not supported")
  }

  func testParseSimpleEnum() throws {
    enum Foo {
      case bar
      case baz
    }
    expect(try Node(from: Foo.self)).toEqual(.stringUnion(["bar", "baz"], .init(Foo.self)))
  }

  func testFlattensEnumCaseWithSingleStructPayload() throws {
    enum Screen {
      struct Connected {
        var flat: String
      }

      case connected(Connected)
      case notConnected
    }
    expect(try Node(from: Screen.self)).toEqual(.objectUnion([
      .init(
        caseName: "connected",
        associatedValues: [
          .init(name: "flat", value: .primitive(.string)),
        ]
      ),
      .init(caseName: "notConnected"),
    ], .init(Screen.self)))
  }

  func testParseEnumWithPayload() throws {
    enum Foo {
      case bar(String)
      case baz(Int?)
      case foo(lol: Bool)
      case named(a: Bool, b: String?)
      case jim
    }
    expect(try Node(from: Foo.self)).toEqual(.objectUnion([
      .init(
        caseName: "bar",
        associatedValues: [.init(name: "bar", value: .primitive(.string))]
      ),
      .init(
        caseName: "baz",
        associatedValues: [.init(name: "baz", value: .primitive(.number(.int)), optional: true)]
      ),
      .init(
        caseName: "foo",
        associatedValues: [.init(name: "lol", value: .primitive(.boolean))]
      ),
      .init(
        caseName: "named",
        associatedValues: [
          .init(name: "a", value: .primitive(.boolean)),
          .init(name: "b", value: .primitive(.string), optional: true),
        ]
      ),
      .init(caseName: "jim"),
    ], .init(Foo.self)))
  }

  func testParseStruct() throws {
    struct Foo {
      var bar: String
      let baz: Int
      var jim: Bool?
      var void: Void
      var never: Never
    }
    expect(try Node(from: Foo.self)).toEqual(.object([
      .init(name: "bar", value: .primitive(.string), optional: false, readonly: false),
      .init(name: "baz", value: .primitive(.number(.int)), optional: false, readonly: true),
      .init(name: "jim", value: .primitive(.boolean), optional: true, readonly: false),
      .init(name: "void", value: .primitive(.void)),
      .init(name: "never", value: .primitive(.never)),
    ], .init(Foo.self)))
  }
}

import XCTest
import XExpect

@testable import TypeScript

final class NodeTests: XCTestCase {
  func testParseNodePrimitive() throws {
    expect(try Node(from: String.self)).toEqual(.primitive(.string))
    expect(try Node(from: Int.self)).toEqual(.primitive(.number))
    expect(try Node(from: Bool.self)).toEqual(.primitive(.boolean))
  }

  func testParseArray() throws {
    expect(try Node(from: [String].self)).toEqual(.array(.primitive(.string)))
    expect(try Node(from: [Int].self)).toEqual(.array(.primitive(.number)))
    expect(try Node(from: [Bool].self)).toEqual(.array(.primitive(.boolean)))
    expect(try Node(from: [[Bool]].self)).toEqual(.array(.array(.primitive(.boolean))))

    struct Foo { var bar: Int }
    expect(try Node(from: [Foo].self)).toEqual(.array(.object([
      .init(name: "bar", value: .primitive(.number)),
    ])))
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
    expect(try Node(from: Foo.self)).toEqual(.union([
      .primitive(.stringLiteral("bar")),
      .primitive(.stringLiteral("baz")),
    ]))
  }

  func testParseEnumWithPayload() throws {
    enum Foo {
      case bar(String)
      case baz(Int?)
      case foo(lol: Bool)
      case named(a: Bool, b: String?)
      case jim
    }
    expect(try Node(from: Foo.self)).toEqual(.union([
      .object([
        .init(name: "case", value: .primitive(.stringLiteral("bar"))),
        .init(name: "bar", value: .primitive(.string)),
      ]),
      .object([
        .init(name: "case", value: .primitive(.stringLiteral("baz"))),
        .init(name: "baz", value: .primitive(.number), optional: true),
      ]),
      .object([
        .init(name: "case", value: .primitive(.stringLiteral("foo"))),
        .init(name: "lol", value: .primitive(.boolean)),
      ]),
      .object([
        .init(name: "case", value: .primitive(.stringLiteral("named"))),
        .init(name: "a", value: .primitive(.boolean)),
        .init(name: "b", value: .primitive(.string), optional: true),
      ]),
      .object([
        .init(name: "case", value: .primitive(.stringLiteral("jim"))),
      ]),
    ]))
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
      .init(name: "baz", value: .primitive(.number), optional: false, readonly: true),
      .init(name: "jim", value: .primitive(.boolean), optional: true, readonly: false),
      .init(name: "void", value: .primitive(.void)),
      .init(name: "never", value: .primitive(.never)),
    ]))
  }
}

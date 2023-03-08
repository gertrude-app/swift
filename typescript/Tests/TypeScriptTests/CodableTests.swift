import XCTest
import XExpect

@testable import TypeScript

enum Baz: Equatable {
  struct Nested: Equatable { let foo: String, bar: Int }
  case foo
  case bar(String)
  case baz(one: String, two: Int)
  case nested(Nested)
  case qux(q: Bool?)
}

final class CodableTests: XCTestCase {
  let bazType = EnumType(
    name: "Baz",
    cases: [
      .init(name: "bar", values: [.init(name: "bar", type: "String")]),
      .init(name: "baz", values: [
        .init(name: "one", type: "String"),
        .init(name: "two", type: "Int"),
      ]),
      .init(
        name: "nested",
        values: [.init(name: "foo", type: "String"), .init(name: "bar", type: "Int")],
        isFlattenedUserStruct: true
      ),
      .init(name: "qux", values: [.init(name: "q", type: "Bool?")]),
      .init(name: "foo", values: []),
    ]
  )

  func testExtractEnumType() throws {
    expect(try EnumType(from: Baz.self)).toEqual(bazType)
  }

  func testCodableConformanceCodegen() {
    expect(bazType.codableConformance).toEqual(
      """
      extension Baz: Codable {
        private struct CaseBar: Codable {
          var `case` = "bar"
          var bar: String
        }

        private struct CaseBaz: Codable {
          var `case` = "baz"
          var one: String
          var two: Int
        }

        private struct CaseNested: Codable {
          var `case` = "nested"
          var foo: String
          var bar: Int
        }

        private struct CaseQux: Codable {
          var `case` = "qux"
          var q: Bool?
        }

        func encode(to encoder: Encoder) throws {
          switch self {
          case .bar(let bar):
            try CaseBar(bar: bar).encode(to: encoder)
          case .baz(let one, let two):
            try CaseBaz(one: one, two: two).encode(to: encoder)
          case .nested(let unflat):
            try CaseNested(foo: unflat.foo, bar: unflat.bar).encode(to: encoder)
          case .qux(let q):
            try CaseQux(q: q).encode(to: encoder)
          case .foo:
            try NamedCase("foo").encode(to: encoder)
          }
        }

        init(from decoder: Decoder) throws {
          let caseName = try NamedCase.name(from: decoder)
          let container = try decoder.singleValueContainer()
          switch caseName {
          case "bar":
            let value = try container.decode(CaseBar.self)
            self = .bar(value.bar)
          case "baz":
            let value = try container.decode(CaseBaz.self)
            self = .baz(one: value.one, two: value.two)
          case "nested":
            let value = try container.decode(CaseNested.self)
            self = .nested(.init(foo: value.foo, bar: value.bar))
          case "qux":
            let value = try container.decode(CaseQux.self)
            self = .qux(q: value.q)
          case "foo":
            self = .foo
          default:
            throw TypeScriptError(message: "Unexpected case name: `\\(caseName)`")
          }
        }
      }
      """
    )
  }

  func testEncodeDecodeFromCodeGen() throws {
    var json = """
    {
      "bar" : "foo",
      "case" : "bar"
    }
    """
    expect(jsonEncode(Baz.bar("foo"))).toEqual(json)
    expect(jsonDecode(json, as: Baz.self)).toEqual(Baz.bar("foo"))

    json = """
    {
      "case" : "qux",
      "q" : true
    }
    """
    expect(jsonEncode(Baz.qux(q: true))).toEqual(json)
    expect(jsonDecode(json, as: Baz.self)).toEqual(Baz.qux(q: true))

    json = """
    {
      "case" : "qux"
    }
    """
    expect(jsonEncode(Baz.qux(q: nil))).toEqual(json)
    expect(jsonDecode(json, as: Baz.self)).toEqual(Baz.qux(q: nil))

    json = """
    {
      "case" : "baz",
      "one" : "foo",
      "two" : 1
    }
    """
    expect(jsonEncode(Baz.baz(one: "foo", two: 1))).toEqual(json)
    expect(jsonDecode(json, as: Baz.self)).toEqual(Baz.baz(one: "foo", two: 1))

    json = """
    {
      "bar" : 3,
      "case" : "nested",
      "foo" : "bar"
    }
    """
    expect(jsonEncode(Baz.nested(.init(foo: "bar", bar: 3)))).toEqual(json)
    expect(jsonDecode(json, as: Baz.self)).toEqual(Baz.nested(.init(foo: "bar", bar: 3)))

    json = """
    {
      "case" : "foo"
    }
    """
    expect(jsonEncode(Baz.foo)).toEqual(json)
    expect(jsonDecode(json, as: Baz.self)).toEqual(Baz.foo)

    // test discriminant is actually used, ignoring excess properties
    json = """
    {
      "case" : "foo",
      "bar" : "foo",
      "one" : "foo",
      "two" : 1,
      "q" : true,
    }
    """
    expect(jsonDecode(json, as: Baz.self)).toEqual(Baz.foo)
  }
}

// this was code-gen'd
extension Baz: Codable {
  private struct CaseBar: Codable {
    var `case` = "bar"
    var bar: String
  }

  private struct CaseBaz: Codable {
    var `case` = "baz"
    var one: String
    var two: Int
  }

  private struct CaseNested: Codable {
    var `case` = "nested"
    var foo: String
    var bar: Int
  }

  private struct CaseQux: Codable {
    var `case` = "qux"
    var q: Bool?
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .foo:
      try NamedCase("foo").encode(to: encoder)
    case .bar(let bar):
      try CaseBar(bar: bar).encode(to: encoder)
    case .baz(let one, let two):
      try CaseBaz(one: one, two: two).encode(to: encoder)
    case .nested(let foo):
      try CaseNested(foo: foo.foo, bar: foo.bar).encode(to: encoder)
    case .qux(let q):
      try CaseQux(q: q).encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try NamedCase.name(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "foo":
      self = .foo
    case "bar":
      let value = try container.decode(CaseBar.self)
      self = .bar(value.bar)
    case "baz":
      let value = try container.decode(CaseBaz.self)
      self = .baz(one: value.one, two: value.two)
    case "nested":
      let value = try container.decode(CaseNested.self)
      self = .nested(.init(foo: value.foo, bar: value.bar))
    case "qux":
      let value = try container.decode(CaseQux.self)
      self = .qux(q: value.q)
    default:
      throw TypeScriptError(message: "Unexpected case name: `\\(caseName)`")
    }
  }
}

// helpers

func jsonEncode(_ value: some Encodable) -> String {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  let encoded = try! encoder.encode(value)
  return String(data: encoded, encoding: .utf8)!
}

func jsonDecode<T: Decodable>(_ string: String, as: T.Type) -> T {
  let decoder = JSONDecoder()
  let data = string.data(using: .utf8)!
  return try! decoder.decode(T.self, from: data)
}

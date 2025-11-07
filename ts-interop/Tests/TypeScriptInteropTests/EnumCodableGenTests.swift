import XCTest
import XExpect

@testable import TypeScriptInterop

typealias EnumType = EnumCodableGen.EnumType

enum Baz: Equatable {
  struct Nested: Equatable { let foo: String, bar: Int, id: UUID }
  case foo
  case bar(String)
  case baz(one: String, two: Int)
  case nested(Nested)
  case qux(q: Bool?)
}

extension EnumCodableGen.EnumType.Case.Value.Name: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self = .some(value)
  }
}

final class CodableTests: XCTestCase {
  let bazType = EnumType(
    name: "Baz",
    cases: [
      .init(name: "bar", values: [.init(name: .none(caseName: "bar"), type: "String")]),
      .init(name: "baz", values: [
        .init(name: "one", type: "String"),
        .init(name: "two", type: "Int"),
      ]),
      .init(
        name: "nested",
        values: [
          .init(name: "foo", type: "String"),
          .init(name: "bar", type: "Int"),
          .init(name: "id", type: "UUID"),
        ],
        isFlattenedUserStruct: true,
      ),
      .init(name: "qux", values: [.init(name: "q", type: "Bool?")]),
      .init(name: "foo", values: []),
    ],
  )

  func testAssociatedValuesWithSameNameAsCase() throws {
    enum DupeNames {
      case a(a: String, b: Bool)
      case b(b: String)
      case c(String, Int)
    }

    let conformance = try (EnumType(from: DupeNames.self)).codableConformance()
    expect(conformance).toContain("self = .a(a: value.a, b: value.b)")
    expect(conformance).toContain("self = .b(b: value.b)")
  }

  func testExtractEnumType() throws {
    expect(try EnumType(from: Baz.self)).toEqual(self.bazType)
  }

  func testFullyQualifiedTypeNames() throws {
    let nested = try EnumType(from: Rofl.Nested.self)
    let firstLine = nested.codableConformance().split(separator: "\n").first!
    expect(firstLine).toEqual("extension Rofl.Nested {")
    expect(typeName(Rofl.Nested.self)).toEqual("Rofl.Nested")
  }

  func testCodableConformanceCodegen() {
    expect(self.bazType.codableConformance()).toEqual(
      """
      extension Baz {
        private struct _NamedCase: Codable {
          var `case`: String
          static func extract(from decoder: Decoder) throws -> String {
            let container = try decoder.singleValueContainer()
            return try container.decode(_NamedCase.self).case
          }
        }

        private struct _TypeScriptDecodeError: Error {
          var message: String
        }

        private struct _CaseBar: Codable {
          var `case` = "bar"
          var bar: String
        }

        private struct _CaseBaz: Codable {
          var `case` = "baz"
          var one: String
          var two: Int
        }

        private struct _CaseNested: Codable {
          var `case` = "nested"
          var foo: String
          var bar: Int
          var id: UUID
        }

        private struct _CaseQux: Codable {
          var `case` = "qux"
          var q: Bool?
        }

        func encode(to encoder: Encoder) throws {
          switch self {
          case .bar(let bar):
            try _CaseBar(bar: bar).encode(to: encoder)
          case .baz(let one, let two):
            try _CaseBaz(one: one, two: two).encode(to: encoder)
          case .nested(let unflat):
            try _CaseNested(foo: unflat.foo, bar: unflat.bar, id: unflat.id).encode(to: encoder)
          case .qux(let q):
            try _CaseQux(q: q).encode(to: encoder)
          case .foo:
            try _NamedCase(case: "foo").encode(to: encoder)
          }
        }

        init(from decoder: Decoder) throws {
          let caseName = try _NamedCase.extract(from: decoder)
          let container = try decoder.singleValueContainer()
          switch caseName {
          case "bar":
            let value = try container.decode(_CaseBar.self)
            self = .bar(value.bar)
          case "baz":
            let value = try container.decode(_CaseBaz.self)
            self = .baz(one: value.one, two: value.two)
          case "nested":
            let value = try container.decode(_CaseNested.self)
            self = .nested(.init(foo: value.foo, bar: value.bar, id: value.id))
          case "qux":
            let value = try container.decode(_CaseQux.self)
            self = .qux(q: value.q)
          case "foo":
            self = .foo
          default:
            throw _TypeScriptDecodeError(message: "Unexpected case name: `\\(caseName)`")
          }
        }
      }
      """,
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
      "foo" : "bar",
      "id" : "00000000-0000-0000-0000-000000000000"
    }
    """
    let id = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    expect(jsonEncode(Baz.nested(.init(foo: "bar", bar: 3, id: id)))).toEqual(json)
    expect(jsonDecode(json, as: Baz.self)).toEqual(Baz.nested(.init(foo: "bar", bar: 3, id: id)))

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
  private struct _NamedCase: Codable {
    var `case`: String
    static func extract(from decoder: Decoder) throws -> String {
      let container = try decoder.singleValueContainer()
      return try container.decode(_NamedCase.self).case
    }
  }

  private struct _TypeScriptDecodeError: Error {
    var message: String
  }

  private struct _CaseBar: Codable {
    var `case` = "bar"
    var bar: String
  }

  private struct _CaseBaz: Codable {
    var `case` = "baz"
    var one: String
    var two: Int
  }

  private struct _CaseNested: Codable {
    var `case` = "nested"
    var foo: String
    var bar: Int
    var id: UUID
  }

  private struct _CaseQux: Codable {
    var `case` = "qux"
    var q: Bool?
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .bar(let bar):
      try _CaseBar(bar: bar).encode(to: encoder)
    case .baz(let one, let two):
      try _CaseBaz(one: one, two: two).encode(to: encoder)
    case .nested(let unflat):
      try _CaseNested(foo: unflat.foo, bar: unflat.bar, id: unflat.id).encode(to: encoder)
    case .qux(let q):
      try _CaseQux(q: q).encode(to: encoder)
    case .foo:
      try _NamedCase(case: "foo").encode(to: encoder)
    }
  }

  public init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "bar":
      let value = try container.decode(_CaseBar.self)
      self = .bar(value.bar)
    case "baz":
      let value = try container.decode(_CaseBaz.self)
      self = .baz(one: value.one, two: value.two)
    case "nested":
      let value = try container.decode(_CaseNested.self)
      self = .nested(.init(foo: value.foo, bar: value.bar, id: value.id))
    case "qux":
      let value = try container.decode(_CaseQux.self)
      self = .qux(q: value.q)
    case "foo":
      self = .foo
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\\(caseName)`")
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

enum Rofl {
  enum Nested {
    case foo
    case bar(String)
  }
}

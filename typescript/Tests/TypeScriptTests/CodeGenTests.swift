import XCTest
import XExpect

@testable import TypeScript

final class CodeGenTests: XCTestCase {

  func testEnumWithNamedAssociatedValues() throws {
    enum Bar {
      case a
      case b(foo: String, bar: Int)
    }

    struct Foo {
      var bar: Bar
    }

    expect(try CodeGen().declaration(for: Foo.self)).toEqual(
      """
      export interface Foo {
        bar: {
          case: 'b';
          foo: string;
          bar: number;
        } | {
          case: 'a';
        };
      }
      """
    )
  }

  func testKitchenSink() throws {
    struct Foo {
      enum Bar {
        case a, b
      }

      struct Tiny {
        var a: String
      }

      struct Nested {
        let a: String
        let b: Int
        let reallyLongPropertyName: Int
      }

      enum Value {
        case string(String)
        case optInt(Int?)
        case named(a: Int, b: String)
        case bare
      }

      let foo: String
      var value: Value
      var inline: Tiny
      var tinyArray: [Tiny]
      var baz: Int?
      var bar: Bar
      let rofl: [String]?
      var nested: Nested
    }

    expect(try CodeGen().declaration(for: Foo.self)).toEqual(
      """
      export interface Foo {
        readonly foo: string;
        value: {
          case: 'string';
          string: string;
        } | {
          case: 'optInt';
          optInt?: number;
        } | {
          case: 'named';
          a: number;
          b: string;
        } | {
          case: 'bare';
        };
        inline: {
          a: string;
        };
        tinyArray: Array<{
          a: string;
        }>;
        baz?: number;
        bar: 'a' | 'b';
        readonly rofl?: string[];
        nested: {
          readonly a: string;
          readonly b: number;
          readonly reallyLongPropertyName: number;
        };
      }
      """
    )
  }

  func testInliningStructDeclsAndMaxLineLen() throws {
    struct Tiny {
      var a: String
      var b: Int
    }

    struct Foo {
      var inline: Tiny
    }

    let normal = try CodeGen(config: .init(compact: false)).declaration(for: Foo.self)
    expect(normal).toEqual(
      """
      export interface Foo {
        inline: {
          a: string;
          b: number;
        };
      }
      """
    )

    let compact = try CodeGen(config: .init(compact: true)).declaration(for: Foo.self)
    expect(compact).toEqual(
      """
      export interface Foo { inline: { a: string; b: number; }; }
      """
    )
  }

  // TODO: unprepresentable tuple should throw: (String?, Int)
}

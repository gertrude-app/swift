import XCTest
import XExpect

@testable import TypeScript

final class CodeGenTests: XCTestCase {
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

      let foo: String
      var inline: Tiny
      var tinyArray: [Tiny]
      var baz: Int?
      var tuple: (String, Int)
      var optTuple: (String, Int?)
      var bar: Bar
      let rofl: [String]?
      var nested: Nested
      var bigTuple: (Nested, [Int])
    }

    expect(try CodeGen().declaration(for: Foo.self)).toEqual(
      """
      export interface Foo {
        readonly foo: string;
        inline: {
          a: string;
        };
        tinyArray: Array<{
          a: string;
        }>;
        baz?: number;
        tuple: [
          string,
          number
        ];
        optTuple: [
          string,
          number?
        ];
        bar: 'a' | 'b';
        readonly rofl?: string[];
        nested: {
          readonly a: string;
          readonly b: number;
          readonly reallyLongPropertyName: number;
        };
        bigTuple: [
          {
            readonly a: string;
            readonly b: number;
            readonly reallyLongPropertyName: number;
          },
          number[]
        ];
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

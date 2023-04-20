import XCTest
import XExpect

@testable import TypeScript

final class CodeGenTests: XCTestCase {
  func testGenericEnum() throws {
    enum RequestState<T, E> {
      case idle
      case loading
      case succeeded(T)
      case failed(E)
    }
    struct Wrap {
      var req: RequestState<Bool, String>
    }
    expect(try CodeGen().declaration(for: Wrap.self)).toEqual(
      """
      export type Wrap = {
        req: {
          case: 'succeeded';
          succeeded: boolean;
        } | {
          case: 'failed';
          failed: string;
        } | {
          case: 'idle';
        } | {
          case: 'loading';
        };
      }
      """
    )
  }

  func testFoundationTypes() throws {
    struct FoundationTypes {
      var date: Date
      var uuid: UUID
    }
    expect(try CodeGen().declaration(for: FoundationTypes.self)).toEqual(
      """
      export type FoundationTypes = {
        date: Date;
        uuid: UUID;
      }
      """
    )
    expect(
      try CodeGen(config: .init(dateType: "IsoDateString", uuidType: "string"))
        .declaration(for: FoundationTypes.self)
    ).toEqual(
      """
      export type FoundationTypes = {
        date: IsoDateString;
        uuid: string;
      }
      """
    )
  }

  func testScreen() throws {
    enum Screen {
      struct Connected {
        var foo: String
      }

      case notConnected
      case connected(Connected)
    }

    expect(try CodeGen().declaration(for: Screen.self)).toEqual(
      """
      export type Screen = {
        case: 'connected';
        foo: string;
      } | {
        case: 'notConnected';
      }
      """
    )
  }

  func testEnumWithNamedAssociatedValues() throws {
    enum Bar {
      case a
      case b(foo: String, bar: Int)
      case c(String)
    }

    struct Foo {
      var bar: Bar
    }

    expect(try CodeGen().declaration(for: Foo.self)).toEqual(
      """
      export type Foo = {
        bar: {
          case: 'b';
          foo: string;
          bar: number;
        } | {
          case: 'c';
          c: string;
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
      export type Foo = {
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
      export type Foo = {
        inline: {
          a: string;
          b: number;
        };
      }
      """
    )

    let alias = try CodeGen(config: .init(compact: false, aliasing: ["inline": "Tiny"]))
      .declaration(for: Foo.self)
    expect(alias).toEqual(
      """
      export type Foo = {
        inline: Tiny;
      }
      """
    )

    let compact = try CodeGen(config: .init(compact: true)).declaration(for: Foo.self)
    expect(compact).toEqual(
      """
      export type Foo = { inline: { a: string; b: number; }; }
      """
    )
  }

  // TODO: unprepresentable tuple should throw: (String?, Int)
}

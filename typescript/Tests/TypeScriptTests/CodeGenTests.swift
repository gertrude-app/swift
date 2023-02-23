import XCTest
import XExpect

@testable import TypeScript

final class CodeGenTests: XCTestCase {
  func testKitchenSink() throws {
    struct Foo {
      enum Bar {
        case a, b
      }

      struct Nested {
        let a: String
        let b: Int
      }

      let foo: String
      var baz: Int?
      var tuple: (String, Int)
      var bar: Bar
      let rofl: [String]?
      var nested: Nested
    }

    expect(try CodeGen().declaration(for: Foo.self)).toEqual(
      """
      export interface Foo {
        readonly foo: string;
        baz?: number;
        tuple: [string, number];
        bar: 'a' | 'b';
        readonly rofl?: string[];
        nested: {
          readonly a: string;
          readonly b: number;
        };
      }
      """
    )
  }
}

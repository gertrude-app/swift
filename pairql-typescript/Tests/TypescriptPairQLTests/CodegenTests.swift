import PairQL
import Runtime
import TypescriptPairQL
import XCTest

final class CodegenTests: XCTestCase {
  func testCoreTypes() throws {
    XCTAssertEqual(String.ts, "export type __self__ = string;")
    XCTAssertEqual(URL.ts, "export type __self__ = string;")
    XCTAssertEqual(UUID.ts, "export type __self__ = UUID;")
    XCTAssertEqual([UUID].ts, "export type __self__ = UUID[];")
    XCTAssertEqual([String].ts, "export type __self__ = string[];")

    XCTAssertEqual(
      [String: String].ts,
      "export type __self__ = { [key: string]: string; };"
    )
  }

  func testVendedTypes() throws {
    XCTAssertEqual(
      SuccessOutput.ts,
      """
      export interface __self__ {
        success: boolean;
      }
      """
    )
    XCTAssertEqual(
      ClientAuth.ts,
      """
      export enum ClientAuth {
        none,
        user,
        admin,
      }
      """
    )
  }

  func testCustomImplementationWins() throws {
    struct Foo: TypescriptRepresentable {
      let bar: String
      static var ts: String { "override" }
    }

    XCTAssertEqual(Foo.ts, "override")
  }

  func testComplexStruct() throws {
    struct Foo: TypescriptRepresentable {
      let id: UUID
      let bar: String
      let baz: Int
      let yup: Bool?
      var strs: [String]
      public let dict: [String: Int]
      var optDict: [String: Bool]?
      var nested: Nested
    }

    struct Nested: TypescriptRepresentable {
      let jim: String
    }

    XCTAssertEqual(
      Foo.ts,
      """
      export interface __self__ {
        id: UUID;
        bar: string;
        baz: number;
        yup?: boolean;
        strs: string[];
        dict: { [key: string]: number; };
        optDict?: { [key: string]: boolean; };
        nested: { jim: string; };
      }
      """
    )
  }
}

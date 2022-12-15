import PairQL
import Runtime
import TypescriptPairQL
import XCTest
import XExpect

final class CodegenTests: XCTestCase {
  func testCoreTypes() throws {
    expect(String.ts).toEqual("export type __self__ = string;")
    expect(URL.ts).toEqual("export type __self__ = string;")
    expect(UUID.ts).toEqual("export type __self__ = UUID;")
    expect([UUID].ts).toEqual("export type __self__ = UUID[];")
    expect([String].ts).toEqual("export type __self__ = string[];")
    expect([String: String].ts).toEqual("export type __self__ = { [key: string]: string; };")
  }

  func testVendedTypes() throws {
    expect(SuccessOutput.ts).toEqual(
      """
      export interface __self__ {
        success: boolean;
      }
      """
    )
    expect(ClientAuth.ts).toEqual(
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

    expect(Foo.ts).toEqual("override")
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

    expect(Foo.ts).toEqual(
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

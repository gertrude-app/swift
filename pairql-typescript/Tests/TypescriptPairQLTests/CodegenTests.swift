import PairQL
import Runtime
import TypescriptPairQL
import XCTest
import XExpect

extension Union2: NamedUnion where A == String, B == Bool {
  public static var __typeName: String {
    "StringOrBool"
  }
}

final class CodegenTests: XCTestCase {
  func testUnnamedUnion() {
    struct Struct: TypescriptRepresentable {
      let items: [Union2<String, UUID>]
    }

    expect(Struct.ts).toEqual(
      """
      export interface __self__ {
        items: Array< | { type: "String"; value: string; } | { type: "UUID"; value: UUID; }>;
      }
      """
    )
  }

  func testNamedUnion() {
    struct Struct: TypescriptRepresentable {
      let items: [Union2<String, Bool>]
    }

    expect(Struct.ts).toEqual(
      """
      export type StringOrBool =
        | { type: "String"; value: string; }
        | { type: "Bool"; value: boolean; }

      export interface __self__ {
        items: Array<StringOrBool>;
      }
      """
    )
  }

  func testUnion2() {
    expect(Union2<String, Int>.ts).toEqual(
      """
      export type __self__ =
        | { type: "String"; value: string; }
        | { type: "Int"; value: number; }
      """
    )
    struct Struct1: PairNestable & TypescriptRepresentable {
      let str: String
    }
    struct Struct2: PairNestable & TypescriptRepresentable {
      let int: Int
    }
    expect(Union2<Struct1, Struct2>.ts).toEqual(
      """
      export type __self__ =
        | { type: "Struct1"; value: { str: string; } }
        | { type: "Struct2"; value: { int: number; } }
      """
    )
  }

  func testArrayOfNonPrimitive() {
    struct Struct: PairNestable & TypescriptRepresentable {
      let str: String
    }
    expect([Struct].ts).toEqual("export type __self__ = Array<{ str: string; }>")
  }

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

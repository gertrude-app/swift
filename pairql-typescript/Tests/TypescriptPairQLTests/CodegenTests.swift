import PairQL
import Runtime
import Shared
import TypescriptPairQL
import XCTest
import XExpect

extension Union2: NamedType where T1 == String, T2 == Bool {
  public static var __typeName: String {
    "StringOrBool"
  }
}

extension DeviceModelFamily: GlobalType {}

final class CodegenTests: XCTestCase {
  func testGlobalNestedTypesDeriveCorrectlyWithInputOutputVars() {
    enum Nested {
      struct Inner: TypescriptNestable, GlobalType {
        let inner: String
      }

      struct Outer: TypescriptNestable, PairOutput, GlobalType {
        let outer: String
        let inners: [Inner]
      }
    }

    struct Pair1: TypescriptPair {
      static var auth: ClientAuth = .admin
      typealias Output = [Nested.Outer]
    }

    struct Pair2: TypescriptPair {
      static var auth: ClientAuth = .admin
      typealias Output = Nested.Outer
    }

    expect(Pair1.Output.outputTs).toEqual(
      """
      export type Output = Array<Outer>
      """
    )
    expect(Pair2.Output.outputTs).toEqual(
      """
      export type Output = Outer
      """
    )
  }

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

  func testNamedType() {
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
    expect(Date.ts).toEqual("export type __self__ = ISODateString;")
    expect(String.ts).toEqual("export type __self__ = string;")
    expect(URL.ts).toEqual("export type __self__ = string;")
    expect(UUID.ts).toEqual("export type __self__ = UUID;")
    expect([UUID].ts).toEqual("export type __self__ = UUID[];")
    expect([String].ts).toEqual("export type __self__ = string[];")
    expect([String: String].ts).toEqual("export type __self__ = { [key: string]: string; };")
  }

  func testGlobalType() {
    // the root type definition
    expect(DeviceModelFamily.ts).toEqual(
      """
      export type DeviceModelFamily = 'macBookAir' | 'macBookPro' | 'mini' | 'iMac' | 'studio' | 'pro' | 'unknown'
      """
    )

    // when nested, use global type name
    struct Struct: TypescriptRepresentable {
      let family: DeviceModelFamily
    }
    expect(Struct.ts).toEqual(
      """
      export interface __self__ {
        family: DeviceModelFamily;
      }
      """
    )
  }

  func testGlobalTypesProperlyNamed() {
    enum Example: TypescriptRepresentable, GlobalType {
      case foo(bar: String)
      case baz(num: Int)
      public static var customTs: String? {
        """
        export type __self__ =
          | { type: 'foo'; bar: string; }
          | { type: 'baz'; num: number; };
        """
      }

      public static var __typeName = "MyExample"
    }

    expect(Example.ts).toEqual(
      """
      export type MyExample =
        | { type: 'foo'; bar: string; }
        | { type: 'baz'; num: number; };
      """
    )
  }

  func testIterableEnum() {
    enum StringEnum: String, Codable, CaseIterable, TypescriptRepresentable {
      case foo, bar, baz
    }
    expect(StringEnum.ts).toEqual("export type __self__ = 'foo' | 'bar' | 'baz'")
  }

  func testVendedTypes() throws {
    expect(NoInput.ts).toEqual("export type __self__ = void;")
    expect(SuccessOutput.ts).toEqual("export type __self__ = SuccessOutput;")
    expect(ClientAuth.ts).toEqual("export type __self__ = 'none' | 'user' | 'admin'")
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

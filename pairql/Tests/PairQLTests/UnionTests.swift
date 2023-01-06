import PairQL
import XCTest
import XExpect

final class UnionTests: XCTestCase {
  func testCustomCodableRoundTripping() {
    let union = [Union2.t1(1), .t2("hi")]
    let expected = """
    [
      {
        "type" : "Int",
        "value" : 1
      },
      {
        "type" : "String",
        "value" : "hi"
      }
    ]
    """

    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let encoded = try! encoder.encode(union)
    let json = String(data: encoded, encoding: .utf8)!
    expect(json).toBe(expected)

    let recoded = try? JSONDecoder().decode([Union2<Int, String>].self, from: encoded)
    expect(recoded).not.toBeNil()
  }

  func testUsesTypeDiscriminant() {
    struct Foo: Codable, Equatable {
      let foo: String
    }

    struct Bar: Codable, Equatable {
      let bar: Int
    }

    let wierdJson = """
    {
      "type" : "Bar",
      "value" : {
        "foo" : "hi",
        "bar" : 1
      }
    }
    """

    let decoded = try? JSONDecoder()
      .decode(Union2<Foo, Bar>.self, from: wierdJson.data(using: .utf8)!)

    expect(decoded).toEqual(Union2<Foo, Bar>.t2(.init(bar: 1)))
  }
}

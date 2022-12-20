import PairQL
import XCTest
import XExpect

final class UnionTests: XCTestCase {
  func testCustomCodableRoundTripping() {
    let union = [Union2.a(1), .b("hi")]
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
}

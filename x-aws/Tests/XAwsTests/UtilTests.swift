import XCTest
import XExpect

@testable import XAws

final class UtilTests: XCTestCase {
  // https://stackoverflow.com/questions/52784823/hmac-sha256-in-swift-4
  func testHmac() {
    let hmac = AWS.Util.hmac(
      "my-secret",
      "An apple a day keeps anyone away, if you throw it hard enough"
    )
    expect(AWS.Util.hex(hmac))
      .toBe("1c161b971ab68e7acdb0b45cca7ae92d574613b77fca4bc7d5c4effab89dab67")
  }

  func testTimestamp() {
    let date = Date(timeIntervalSince1970: 1_369_353_600)
    let timestamp = AWS.Util.timestamp(date)
    expect(timestamp).toBe("20130524T000000Z")

    let yyyymmdd = AWS.Util.yyyymmdd(date)
    expect(yyyymmdd).toBe("20130524")
  }

  func testLowercase() async throws {
    let result = AWS.Util.lowercase("HELLO")
    expect(result).toBe("hello")
  }

  func testUriEncode() async throws {
    let result = AWS.Util.uriEncode("hello world")
    expect(result).toBe("hello%20world")

    // reserved chars preserved
    expect(AWS.Util.uriEncode("ABab01-._~")).toBe("ABab01-._~")

    // space encoded as `%20`
    expect(AWS.Util.uriEncode(" ")).toBe("%20")

    // `;` encoded as `%3B`
    expect(AWS.Util.uriEncode(";")).toBe("%3B")

    // letters in hex value must be uppercase
    expect(AWS.Util.uriEncode("^")).toBe("%5E")

    // slash encoded as `%2F`
    expect(AWS.Util.uriEncode("/")).toBe("%2F")

    // path encoding
    expect(AWS.Util.uriEncode("/test.txt", isObjectKeyName: true)).toBe("/test.txt")

    // asterisk should be encoded as `%2A`
    expect(AWS.Util.uriEncode("*")).toBe("%2A")
  }

  func testHex() async throws {
    expect(AWS.Util.hex("N".data(using: .utf8)!)).toBe("4e")
  }

  func testSha256() async throws {
    expect(AWS.Util.sha256("hello"))
      .toBe("2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
    expect(AWS.Util.sha256(""))
      .toBe("e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  }
}

import XCTest

@testable import XHttp

final class XHttpTests: XCTestCase {
  func testGetDecoding() async throws {
    struct XkcdComic: Decodable, Equatable {
      let num: Int
      let title: String
      let month: String
      let year: String
    }

    let bobbyTables = try await HTTP.get(
      "https://xkcd.com/327/info.0.json",
      decoding: XkcdComic.self,
    )

    XCTAssertEqual(
      bobbyTables,
      XkcdComic(num: 327, title: "Exploits of a Mom", month: "10", year: "2007"),
    )
  }
}

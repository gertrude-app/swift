import Gertie
import XCTest
import XExpect

final class AppcastQueryTests: XCTestCase {
  func testUrlString() {
    let cases = [
      (
        AppcastQuery(channel: .beta, force: true, version: "1.0.0"),
        "?version=1.0.0&force=true&channel=beta",
      ),
      (
        .init(channel: nil, force: nil, version: nil),
        "",
      ),
      (
        .init(channel: .beta, force: true, version: "1.0.0", requestingAppVersion: "4.9.0"),
        "?requestingAppVersion=4.9.0&force=true&version=1.0.0&channel=beta",
      ),
    ]

    for (query, expected) in cases {
      expect(query.urlString).toEqual(expected)
    }
  }
}

import XCTest
import XCTVapor
import XExpect

@testable import Api

final class AppcastTests: ApiTestCase {
  func testAppcastVersions() async throws {
    try await replaceAllReleases(with: [
      Release("2.0.0", channel: .stable, pace: nil, createdAt: .epoch),
      Release("2.1.0", channel: .canary, pace: nil, createdAt: .epoch.advanced(by: .days(10))),
      Release("2.1.1", channel: .stable, pace: nil, createdAt: .epoch.advanced(by: .days(20))),
    ])

    try app.test(.GET, "appcast.xml", afterResponse: { res in
      expect(filenames(from: res)).toEqual([
        "Gertrude.2.1.1.zip",
        "Gertrude.2.0.0.zip",
      ])
    })

    // canary is one behind stable, so...
    try app.test(.GET, "appcast.xml?channel=canary", afterResponse: { res in
      expect(filenames(from: res)).toEqual([
        "Gertrude.2.1.1.zip", // <-- ...includes stable
        "Gertrude.2.1.0.zip",
        "Gertrude.2.0.0.zip",
      ])
    })
  }

  func filenames(from response: XCTHTTPResponse) -> [String] {
    response.body.string.split(separator: "\n")
      .filter { $0.contains("url=") }
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .compactMap { $0.split(separator: "/").last }
      .map { String($0.replacingOccurrences(of: "\"", with: "")) }
  }
}

import LibFilter
import XCTest

final class FilterTests: XCTestCase {
  func testDecideFlow() throws {
    let cases: [(host: String?, url: String?, src: String, allow: Bool)] = [
      (host: nil, url: nil, src: "HashtagImagesExtension", allow: false),
      (host: nil, url: nil, src: ".com.apple.Spotlight", allow: false),
      (host: nil, url: nil, src: "com.widget", allow: true),
      (host: "cdn2.smoot.apple.com", url: nil, src: "com.widget", allow: false),
      (host: "media.tenor.co", url: nil, src: "com.widget", allow: false),
      (host: "wa.tenor.co", url: nil, src: "com.widget", allow: false),
      (host: "api.tenor.com", url: nil, src: "AL798K98FX.com.skype.skype", allow: false),
      (host: "giphy.com", url: nil, src: "com.widget", allow: false),
      (host: "media0.giphy.com", url: nil, src: "com.widget", allow: false),
      (host: "media.fosu2-1.fna.whatsapp.net", url: nil, src: "", allow: false),
      // block these only from Messages app, they allow searching/viewing app store content
      (host: "is1-ssl.mzstatic.com", url: nil, src: ".com.apple.MobileSMS", allow: false),
      (host: "is1-ssl.mzstatic.com", url: nil, src: "com.widget", allow: true),
      // these totally kill iMessage App store app, which is not preferred for some parents
      // (host: "amp-api-edge.apps.apple.com", url: nil, src: ".com.apple.MobileSMS", allow: false),
      // (host: "amp-api-edge.apps.apple.com", url: nil, src: "com.widget", allow: true),
    ]

    for (host, url, src, expected) in cases {
      XCTAssertEqual(decideFlow(hostname: host, url: url, sourceId: src), expected)
    }
  }
}

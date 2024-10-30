import GertieIOS
import LibFilter
import XCTest

final class FilterTests: XCTestCase {
  func testBlocksFlow() {
    let cases: [(host: String?, url: String?, src: String, block: Bool)] = [
      (host: nil, url: nil, src: "HashtagImagesExtension", block: true),
      (host: nil, url: nil, src: ".com.apple.Spotlight", block: true),
      (host: nil, url: nil, src: "com.widget", block: false),
      (host: "cdn2.smoot.apple.com", url: nil, src: "com.widget", block: true),
      (host: "media.tenor.co", url: nil, src: "com.widget", block: true),
      (host: "wa.tenor.co", url: nil, src: "com.widget", block: true),
      (host: "api.tenor.com", url: nil, src: "AL798K98FX.com.skype.skype", block: true),
      (host: "giphy.com", url: nil, src: "com.widget", block: true),
      (host: "media0.giphy.com", url: nil, src: "com.widget", block: true),
      (host: "media.fosu2-1.fna.whatsapp.net", url: nil, src: "", block: true),
      // block these only from Messages app, they allow searching/viewing app store content
      (host: "is1-ssl.mzstatic.com", url: nil, src: ".com.apple.MobileSMS", block: true),
      (host: "is1-ssl.mzstatic.com", url: nil, src: "com.widget", block: false),
      // these totally kill iMessage App store app, which is not preferred for some parents
      // (host: "amp-api-edge.apps.apple.com", url: nil, src: ".com.apple.MobileSMS", block: true),
      // (host: "amp-api-edge.apps.apple.com", url: nil, src: "com.widget", block: false),
    ]

    for (host, url, src, expected) in cases {
      XCTAssertEqual(
        BlockRule.defaults.blocksFlow(hostname: host, url: url, bundleId: src),
        expected
      )
    }
  }
}

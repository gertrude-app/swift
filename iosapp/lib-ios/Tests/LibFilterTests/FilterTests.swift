import GertieIOS
import LibFilter
import XCTest

final class FilterTests: XCTestCase {
  func testBlocksFlow() {
    let cases: [(BlockRule, Test)] = [
      // hostnameContains()
      (.hostnameContains("a.com"), .init(host: "bla.com", block: true)),
      (.hostnameContains("a.com"), .init(host: "bla.com.uk", block: true)),
      (.hostnameContains("a.com"), .init(host: "blah.com", block: false)),
      (.hostnameContains("a.com"), .init(host: "b.com", url: "b.com/a.com", block: false)),
      // hostnameEquals()
      (.hostnameEquals("a.com"), .init(host: "a.com", block: true)),
      (.hostnameEquals("a.com"), .init(host: "a.com.uk", block: false)),
      (.hostnameEquals("a.com"), .init(host: "bla.com", block: false)),
      (.hostnameEquals("a.com"), .init(host: "b.com", block: false)),
      (.hostnameEquals("a.com"), .init(host: "b.com", url: "a.com", block: false)),
      // hostnameEndsWith()
      (.hostnameEndsWith("a.com"), .init(host: "bla.com", block: true)),
      (.hostnameEndsWith("a.com"), .init(host: "www.a.com", block: true)),
      (.hostnameEndsWith("a.com"), .init(host: "bla.com.uk", block: false)),
      // safely deriving hostname from url only
      (.hostnameEndsWith("a.com"), .init(host: nil, url: "https://bla.com/", block: true)),
      (.hostnameEndsWith("a.com"), .init(host: nil, url: "https://bla.com", block: true)),
      (.hostnameEndsWith("a.com"), .init(host: nil, url: "http://bla.com", block: true)),
      (.hostnameEndsWith("a.com"), .init(host: nil, url: "ftp://bla.com", block: false)),
      (.hostnameEndsWith("a.com"), .init(host: nil, url: "bla.com", block: false)),
      (
        .hostnameEquals("www.safe.com"),
        .init(host: nil, url: "https://www.safe.com/foo/bar", block: true)
      ),
      (
        .hostnameEndsWith("safe.com"),
        .init(host: nil, url: "https://foo.bar-sobaz.qux.safe.com/foo/bar", block: true)
      ),
      // unless(rule:negatedBy)
      (
        .unless(
          rule: .bundleIdContains("com.mobile.Safari"),
          negatedBy: [.hostnameEndsWith("safe.com"), .hostnameEndsWith("kids.org")]
        ),
        .init(host: "bad.com", src: ".com.mobile.Safari", block: true)
      ),
      (
        .unless(
          rule: .bundleIdContains("com.mobile.Safari"),
          negatedBy: [.hostnameEndsWith("safe.com"), .hostnameEndsWith("kids.org")]
        ),
        .init(host: "www.kids.org", src: ".com.mobile.Safari", block: false)
      ),
      (
        .unless(
          rule: .bundleIdContains("com.mobile.Safari"),
          negatedBy: [.hostnameEndsWith("safe.com"), .hostnameEndsWith("kids.org")]
        ),
        .init(host: "bad.com", src: "com.other.app", block: false)
      ),
    ]

    for (rule, t) in cases {
      XCTAssertEqual(
        rule.blocksFlow(hostname: t.host, url: t.url, bundleId: t.src),
        t.block
      )
    }
  }

  func testDefaultsBlocksFlow() {
    let cases: [Test] = [
      .init(host: nil, url: nil, src: "HashtagImagesExtension", block: true),
      .init(host: nil, url: nil, src: ".com.apple.Spotlight", block: true),
      .init(host: nil, url: nil, src: "com.widget", block: false),
      .init(host: "cdn2.smoot.apple.com", url: nil, src: "com.widget", block: true),
      .init(host: "media.tenor.co", url: nil, src: "com.widget", block: true),
      .init(host: "wa.tenor.co", url: nil, src: "com.widget", block: true),
      .init(host: "api.tenor.com", url: nil, src: "AL798K98FX.com.skype.skype", block: true),
      .init(host: "giphy.com", url: nil, src: "com.widget", block: true),
      .init(host: "media0.giphy.com", url: nil, src: "com.widget", block: true),
      .init(host: "media.fosu2-1.fna.whatsapp.net", url: nil, src: "", block: true),
      .init(host: "is1-ssl.mzstatic.com", url: nil, src: ".com.apple.MobileSMS", block: true),
      .init(host: "is1-ssl.mzstatic.com", url: nil, src: "com.widget", block: false),
    ]

    for t in cases {
      XCTAssertEqual(
        BlockRule.defaults.blocksFlow(hostname: t.host, url: t.url, bundleId: t.src),
        t.block
      )
    }
  }
}

private struct Test {
  let host: String?
  let url: String?
  let src: String
  let block: Bool

  init(host: String? = nil, url: String? = nil, src: String = "com.acme.app", block: Bool) {
    self.host = host
    self.url = url
    self.src = src
    self.block = block
  }
}

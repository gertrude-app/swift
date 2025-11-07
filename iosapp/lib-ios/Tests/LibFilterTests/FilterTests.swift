import GertieIOS
import LibFilter
import XCTest

final class FilterTests: XCTestCase {
  func testBlocksFlow() {
    let cases: [(BlockRule, Test)] = [
      // hostnameContains()
      (.hostnameContains(value: "a.com"), .init(host: "bla.com", block: true)),
      (.hostnameContains(value: "a.com"), .init(host: "bla.com.uk", block: true)),
      (.hostnameContains(value: "a.com"), .init(host: "blah.com", block: false)),
      (.hostnameContains(value: "a.com"), .init(host: "b.com", url: "b.com/a.com", block: false)),
      // hostnameEquals()
      (.hostnameEquals(value: "a.com"), .init(host: "a.com", block: true)),
      (.hostnameEquals(value: "a.com"), .init(host: "a.com.uk", block: false)),
      (.hostnameEquals(value: "a.com"), .init(host: "bla.com", block: false)),
      (.hostnameEquals(value: "a.com"), .init(host: "b.com", block: false)),
      (.hostnameEquals(value: "a.com"), .init(host: "b.com", url: "a.com", block: false)),
      // hostnameEndsWith()
      (.hostnameEndsWith(value: "a.com"), .init(host: "bla.com", block: true)),
      (.hostnameEndsWith(value: "a.com"), .init(host: "www.a.com", block: true)),
      (.hostnameEndsWith(value: "a.com"), .init(host: "bla.com.uk", block: false)),
      // safely deriving hostname from url only
      (.hostnameEndsWith(value: "a.com"), .init(host: nil, url: "https://bla.com/", block: true)),
      (.hostnameEndsWith(value: "a.com"), .init(host: nil, url: "https://bla.com", block: true)),
      (.hostnameEndsWith(value: "a.com"), .init(host: nil, url: "http://bla.com", block: true)),
      (.hostnameEndsWith(value: "a.com"), .init(host: nil, url: "ftp://bla.com", block: false)),
      (.hostnameEndsWith(value: "a.com"), .init(host: nil, url: "bla.com", block: false)),
      (
        .hostnameEquals(value: "www.safe.com"),
        .init(host: nil, url: "https://www.safe.com/foo/bar", block: true)
      ),
      (
        .hostnameEndsWith(value: "safe.com"),
        .init(host: nil, url: "https://foo.bar-sobaz.qux.safe.com/foo/bar", block: true)
      ),
      // unless(rule:negatedBy)
      (
        .unless(
          rule: .bundleIdContains(value: "com.mobile.Safari"),
          negatedBy: [.hostnameEndsWith(value: "safe.com"), .hostnameEndsWith(value: "kids.org")],
        ),
        .init(host: "bad.com", src: ".com.mobile.Safari", block: true)
      ),
      (
        .unless(
          rule: .bundleIdContains(value: "com.mobile.Safari"),
          negatedBy: [.hostnameEndsWith(value: "safe.com"), .hostnameEndsWith(value: "kids.org")],
        ),
        .init(host: "www.kids.org", src: ".com.mobile.Safari", block: false)
      ),
      (
        .unless(
          rule: .bundleIdContains(value: "com.mobile.Safari"),
          negatedBy: [.hostnameEndsWith(value: "safe.com"), .hostnameEndsWith(value: "kids.org")],
        ),
        .init(host: "bad.com", src: "com.other.app", block: false)
      ),
      // flowTypeIs()
      (.flowTypeIs(value: .browser), .init(flowType: .browser, block: true)),
      (.flowTypeIs(value: .browser), .init(flowType: .socket, block: false)),
      (.flowTypeIs(value: .browser), .init(flowType: nil, block: false)),
      (.flowTypeIs(value: .socket), .init(flowType: .browser, block: false)),
      (.flowTypeIs(value: .socket), .init(flowType: .socket, block: true)),
      (.flowTypeIs(value: .socket), .init(flowType: nil, block: false)),
    ]

    for (rule, t) in cases {
      XCTAssertEqual(
        rule.blocksFlow(.init(
          hostname: t.host,
          url: t.url,
          bundleId: t.src,
          flowType: t.flowType,
        )),
        t.block,
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
        BlockRule.Legacy.defaults.map(\.current).blocksFlow(.init(
          hostname: t.host,
          url: t.url,
          bundleId: t.src,
          flowType: nil,
        )),
        t.block,
      )
    }
  }
}

private struct Test {
  let host: String?
  let url: String?
  let src: String
  let flowType: FlowType?
  let block: Bool

  init(
    host: String? = nil,
    url: String? = nil,
    src: String = "com.acme.app",
    flowType: FlowType? = nil,
    block: Bool,
  ) {
    self.host = host
    self.url = url
    self.src = src
    self.flowType = flowType
    self.block = block
  }
}

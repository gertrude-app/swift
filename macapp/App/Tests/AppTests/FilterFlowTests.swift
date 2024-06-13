import Gertie
import XCTest

@testable import Core

class FilterFlowTests: XCTestCase {
  func testExtractsHostnameFromDesc() throws {
    let flow = TestDesc(hostname: "www.wikipedia.org").flow
    XCTAssertEqual(flow.hostname, "www.wikipedia.org")
  }

  func testExtractsIpv4IpFromDesc() throws {
    let cases = [
      ("208.80.154.224:443", "208.80.154.224"),
      ("1.2.3.4:80", "1.2.3.4"),
      ("0.0.0.0:443", "0.0.0.0"),
    ]
    for (endpoint, expected) in cases {
      let flow = TestDesc(endpoint: endpoint).flow
      XCTAssertEqual(flow.ipAddress, expected)
    }
  }

  func testExtractsIpV6FromDesc() throws {
    let cases = [
      ("2001:4998:24:120d::1:0.443", "2001:4998:24:120d::1:0"),
      ("2001:4998:60:800::1105.443", "2001:4998:60:800::1105"),
      ("2001:4998:58:204::2000.443", "2001:4998:58:204::2000"),
      ("::.443", "::"), // the `any` "unspecified" adddress
    ]
    for (endpoint, expected) in cases {
      let flow = TestDesc(endpoint: endpoint).flow
      XCTAssertEqual(flow.ipAddress, expected)
    }
  }

  func testIsLocal() throws {
    let cases = [
      ("12.2.3.4:80", false),
      ("::1.80", true),
      ("0:0:0:0:0:0:0:1.80", true),
      ("127.0.0.1:80", true),
      ("127.0.0.1:443", true),
      ("2001:4998:24:120d::1:0.443", false),
    ]
    for (endpoint, expected) in cases {
      let flow = TestDesc(endpoint: endpoint).flow
      XCTAssertEqual(flow.isLocal, expected)
    }
  }

  func testSetHostnameFromFlowBytes() throws {
    let cases = [
      (
        "•••••••••••••••••••j.••••A••••••••••i••••••••6••t••_1••••••••d•••nq•••l••••••••••••••••••/•••0•••••••••••••/•5••••ZZ•••••••••••www.malware-traffic-analysis.net•••••••••••••••••••••••••••••••••••••••••••1••S6•N•••XJ••••••••••••••••oW••••5••••8••••••jA•••••V•••••••••••",
        "www.malware-traffic-analysis.net"
      ),
      (
        "•••••••••••••••••••j.••••A••••••••••i••••••••6••t••_1••••••••d•••nq•••l••••••••••••••••••/•••0•••••••••••••/•5••••ZZ•••••••••••cdn.sstatic.net•••••••••••••••••••••••••••••••••••••••••••1••S6•N•••XJ••••••••••••••••oW••••5••••8••••••jA•••••V•••••••••••",
        "cdn.sstatic.net"
      ),
      (
        "••••L•••H•••2••pY••••••p••C•••n••_••M••t•••••E••4••••••7•••••••••b••D••RDm••••zz•••••••••/•••0•••••••••••••/•5•••••••••••••••••www.yahoo.com••••••••••••••••••••••••••••••••••••••••h2•http/1.1••••••••••••••••••••••••••••••••••••3•••••••••••••••k••6•••",
        "www.yahoo.com"
      ),
      (
        "•••••••••••••••s•O••••••••••••M••t••••Y•••••UN•••sNB•••••••jQ••••H•G•••••X•••••••••••••••/•••0•••••••••••••/•5•••••••••••••••••slack.com••••••••••••••••••••••••••••••••••••••••h2•http/1.1••••••••••••••••••••••••••••••••••••3•••••••••••••••••••••••42•",
        "slack.com"
      ),
      (
        "•••••••••••h•••A•••••f•••A••••-2••p•••••••••R1••••••••••B•••••l9•••k•••••••••••••••••/•••0•••••••••••••••••••/•5•••••••••••••••vortex.data.microsoft.com••••••••••••••••••••••••••••••••••••••••••••••••••••••••3•••••••••D•••B_H•••••5••••w•••?••G•W7••2•",
        "vortex.data.microsoft.com"
      ),
      (
        "••••••••••••W••••••••••S=•i•U•hi••••••••••A••••a••a•••••i••••U-•5••••••••••••••••••••••••/•••0•••••••••••••/•5•••••••••••••••••az764295.vo.msecnd.net••••••••••••••••••••••••••••••••••••••••h2•http/1.1••••••••••••••••••••••••••••••••••••3•••••••••••••",
        "az764295.vo.msecnd.net"
      ),
      (
        "••••••••••••••F••••••••••••••9••25•1••g•u•••••••••••••••••B•••C••qwR•J8•••••••jj•••••••••/•••0•••••••••••••/•5••••••••••••••••••••••Di•••••h2•-•••••••••••••••h2•http/1.1•••••••••••••••••••••••api-u-alpha.global.ssl.fastly.net••••••••••••••••••3•••••••••••••Q••••••••••••E••j•••W••SK••s•p•v••••••••••••••N••_••••K•••••••••••••V••i•••i••••-••••••_•j•••R•••••••••••.•••••••Q•••r••••O•5••••c••••k•r•••l••••O4",
        "api-u-alpha.global.ssl.fastly.net"
      ),
      (
        "••••••••••••••y••••W•••••••zX••yOS••••N••T•••••iM••••hR•••••••l•••/•1Kh••VR•••JJ•••••••••/•••0•••••••••••••/•5•••••••••-••••••••••••••••••••Di•••••h2•••••••••••••••••••••••••c••••••••••••••h2•http/1.1•••••••••a.espncdn.com••••••••••••••••••••••••••••••••••••••••3•••••••••c•••••••f•1•ctZ••R••a•5zfc•••••••••••t••7•••3•R•••5••A•j•••J•4••••••Q••f••Fjx•••8•••••u••fWes••••d•u••••••y•••••Fn•7••••••••••••T<…>",
        "a.espncdn.com"
      ),
    ]
    for (bytes, hostname) in cases {
      var flow = TestDesc(appId: ".com.apple.Safari").flow
      flow.parseOutboundData(byteString: bytes)
      XCTAssertEqual(flow.hostname, hostname)
    }
  }

  func testAssemblesUrlFromHttpRequest() throws {
    let cases = [
      (
        "GET•/cards•HTTP/1.1••Host••api-win.howtocomputer.link••Connection••keep-alive••User-Agent••Mozilla/5.0••Macintosh••Intel•Mac•OS•X•10_15_7••AppleWebKit/537.36••KHTML••like•Gecko••Chrome/88.0.4324.152•Safari/537.36••Accept•••/•••Sec-GPC••1••Origin••htt",
        "http://api-win.howtocomputer.link/cards", "api-win.howtocomputer.link"
      ),
    ]
    for (bytes, url, hostname) in cases {
      var flow = TestDesc(appId: ".com.apple.Safari").flow
      flow.parseOutboundData(byteString: bytes)
      XCTAssertEqual(flow.url, url)
      XCTAssertEqual(flow.hostname, hostname)
    }
  }

  func testExtractsPortFromEndpoint() throws {
    let cases: [(String, Core.Port?)] = [
      ("unexpected", nil),
      ("1.2.3.4:80", .http(80)),
      ("1.2.3.4:443", .https(443)),
      ("1.2.3.4:53", .dns(53)),
      ("1.2.3.4:222", .other(222)),
      ("::.443", .https(443)),
      ("::.80", .http(80)),
      ("::.53", .dns(53)),
      ("::.222", .other(222)),
    ]
    for (remoteEndpoint, port) in cases {
      let flow = TestDesc(endpoint: remoteEndpoint).flow
      XCTAssertEqual(flow.port, port)
    }
  }

  func testExtractsProtocolFromDesc() throws {
    let cases: [(Int, IpProtocol)] = [
      (6, .tcp(6)),
      (17, .udp(17)),
      (26, .other(26)),
    ]
    for (actual, expected) in cases {
      let flow = TestDesc(ipProtocol: actual).flow
      XCTAssertEqual(flow.ipProtocol, expected)
    }
  }
}

struct TestDesc {
  var hostname: String = "www.wikipedia.org"
  var endpoint: String = "0.0.0.0:80"
  var appId: String = ".com.apple.Safari"
  var ipProtocol: Int = 6

  init(appId: String) {
    self.appId = appId
  }

  init(endpoint: String) {
    self.endpoint = endpoint
  }

  init(hostname: String) {
    self.hostname = hostname
  }

  init(ipProtocol: Int) {
    self.ipProtocol = ipProtocol
  }

  var flow: FilterFlow { FilterFlow(url: nil, description: self.get) }

  var get: String {
    """
        identifier = 5B4BF304-E46B-4602-9C09-7EF0BC9D1757
        hostname = \(self.hostname)
        sourceAppIdentifier = \(self.appId)
        sourceAppVersion = 14.0.1
        sourceAppUniqueIdentifier = 20:{length = 20, bytes = 0xf0c4232c3a01828c129246f4b575524558714576}
        procPID = 41141
        eprocPID = 41141
        direction = outbound
        inBytes = 0
        outBytes = 0
        signature = 32:{...}
        remoteEndpoint = \(self.endpoint)
        protocol = \(self.ipProtocol)
        family = 2
        type = 1
        procUUID = 5DBC6092-DC53-3DA2-A09C-48B532B84D11
        eprocUUID = 5DBC6092-DC53-3DA2-A09C-48B532B84D11
    """
  }
}

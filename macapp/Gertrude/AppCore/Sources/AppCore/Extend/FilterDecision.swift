import Foundation
import Shared
import SharedCore

extension FilterDecision: Identifiable {}

extension FilterDecision {
  var displayUrl: String {
    if let url = url {
      return url
    } else if let hostname = hostname, !hostname.isEmpty {
      return hostname
    } else if let ipAddress = ipAddress, !ipAddress.isEmpty {
      return ipAddress
    } else {
      return "<unknown>"
    }
  }

  var filterString: String {
    let parts: [String] = [
      hostname,
      ipAddress,
      url,
      app?.bundleId,
      app?.slug,
      app?.displayName,
      app?.categories.joined(separator: " "),
      ipProtocol?.shortDescription,
    ].compactMap { $0 }
    return parts.joined(separator: " ").lowercased()
  }
}

// debug mock extension

#if DEBUG
  extension FilterDecision {
    static func mock() -> FilterDecision {
      let apps = [
        AppDescriptor(
          bundleId: "com.brave",
          slug: "brave",
          displayName: "Brave",
          categories: ["browser"]
        ),
        AppDescriptor(
          bundleId: "com.slack",
          slug: "slack",
          displayName: "Slack",
          categories: ["chat", "utils"]
        ),
        AppDescriptor(
          bundleId: "com.unknown",
          slug: nil,
          displayName: nil,
          categories: []
        ),
        AppDescriptor(
          bundleId: "com.gertrude",
          slug: "gertrud",
          displayName: "Gertrude",
          categories: []
        ),
        AppDescriptor(
          bundleId: "com.widget",
          slug: "widget",
          displayName: "Acme WIdget",
          categories: []
        ),
        nil,
        nil,
      ]

      let app = apps.shuffled().first!
      let verdicts: [NetworkDecisionVerdict] = [.block, .block, .allow]
      let ips = ["251.3.35.525", "2603:6011:713f:1c:b618:d1ff:fedf:2914", "10.0.1.200"]
      let protocols: [IpProtocol] = [.tcp(18), .udp(88)]
      let hosts = ["example.com", ""]
      let urls = ["https://www.site.com/foo/bar", nil, nil, nil, nil]
      let counts = [1, 1, 1, 4, 1, 26]

      return .init(
        id: UUID(),
        verdict: verdicts.shuffled().first!,
        reason: .defaultNotAllowed,
        count: counts.shuffled().first!,
        app: app,
        filterFlow: .init(
          url: urls.shuffled().first!,
          ipAddress: ips.shuffled().first,
          hostname: hosts.shuffled().first,
          ipProtocol: protocols.shuffled().first
        ),
        responsibleKeyId: nil
      )
    }

    static func mockUnknown() -> Self {
      var req = mock()
      req.app = nil
      req.count = 5
      return req
    }
  }
#endif

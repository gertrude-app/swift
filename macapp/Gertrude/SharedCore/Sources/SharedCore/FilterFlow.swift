import Foundation
import Shared

#if os(macOS)
  import Network
#endif

public struct FilterFlow: Equatable, Codable {
  public var url: String?
  public var ipAddress: String?
  public var hostname: String?
  public var bundleId: String?
  public var remoteEndpoint: String?
  // @TODO, does this need to live here? it get's serialized and passed over IPC
  public var sourceAuditToken: Data?
  public var userId: uid_t?
  public var port: NetworkPort?
  public var ipProtocol: IpProtocol?
  public var isDnsRequest: Bool { isUDP && port == .dns(53) }
  public var isUDP: Bool { ipProtocol == .udp(Int32(IPPROTO_UDP)) }

  public var isLocal: Bool {
    if ipAddress == "127.0.0.1" {
      return true
    }
    if hostname == "localhost" {
      return true
    }
    return false
  }

  public var isPrivateNetwork: Bool {
    guard let ip = ipAddress else {
      return false
    }
    // https://en.wikipedia.org/wiki/Reserved_IP_addresses
    let prefixes = ["10.", "100.64.", "192.0.0.", "192.168."]
    for prefix in prefixes {
      if ip.hasPrefix(prefix) {
        return true
      }
    }

    if !ip.hasPrefix("172.") {
      return false
    }

    let parts = ip.split(separator: ".")
    if parts.count < 2 {
      return false
    }

    if let second = Int(parts[1]), second >= 16, second <= 31 {
      return true
    }

    return false
  }

  public mutating func parseOutboundData(byteString: String) {
    if let range = byteString.range(
      of: #"^(GET|POST|PUT|PATCH|DELETE)•[^•]+•HTTP/[^•]+••Host••[^•]+"#,
      options: .regularExpression
    ) {
      let firstChunk = String(byteString[range])
      let pieces = firstChunk.components(separatedBy: "•").filter { $0 != "" }
      url = "http://" + pieces[4] + pieces[1]
      hostname = pieces[4]
      return
    }

    if let range = byteString.range(
      of: #"[a-z0-9_-]{2,}\.[a-z0-9_-]{2,}(\.[a-z0-9_-]{2,})?(\.[a-z0-9_-]{2,})?"#,
      options: .regularExpression
    ) {
      hostname = String(byteString[range])
    }
  }

  public init(
    url: String? = nil,
    ipAddress: String? = nil,
    hostname: String? = nil,
    bundleId: String? = nil,
    remoteEndpoint: String? = nil,
    sourceAuditToken: Data? = nil,
    userId: uid_t? = nil,
    port: NetworkPort? = nil,
    ipProtocol: IpProtocol? = nil
  ) {
    self.url = url
    self.ipAddress = ipAddress
    self.hostname = hostname
    self.bundleId = bundleId
    self.remoteEndpoint = remoteEndpoint
    self.sourceAuditToken = sourceAuditToken
    self.userId = userId
    self.port = port
    self.ipProtocol = ipProtocol
  }

  public init(url: String?, description: String) {
    self.url = url
    let descLines = description.components(separatedBy: "\n")

    // @TODO: `protocol`, `remoteEndpoint`, `port`, and `ipAddress`
    // can be resolved faster and more stably by casting the `NEFilterFlow`
    // to a `NEFilterSocketFlow`, and insepecting the `.remoteEndpoint` class,
    // `.socketProtocol`, `.socketType`, etc. Not doing now (4/22/21) b/c it's
    // mostly just a speed and forward-compat issue, not pressing, and i still
    // don't know if i'm going to abandon this project, but if there is a long-term
    // it would definitely be better to reduce dependence on this debug description
    // and would likely be much faster if we could do less string matching/regex
    // that said, `hostname` and `bundleId` don't have easy workarounds

    for untrimmedLine in descLines {
      let line = untrimmedLine.trimmingCharacters(in: .whitespaces)
      if line.hasPrefix("sourceAppIdentifier") {
        bundleId = line.components(separatedBy: " = ").last ?? ""
      } else if line.hasPrefix("protocol") {
        ipProtocol = IpProtocol(line.components(separatedBy: " = ").last ?? "")
      } else if line.hasPrefix("hostname") {
        hostname = line.components(separatedBy: " = ").last ?? ""
      } else if line.hasPrefix("remoteEndpoint") {
        remoteEndpoint = line.components(separatedBy: " = ").last ?? line
        if remoteEndpoint?.matchesRegex(#"^\d+\.\d+\.\d+\.\d+:(\d+)$"#) == true {
          let parts: [String] = remoteEndpoint?.components(separatedBy: ":") ?? []
          if parts.count == 2 {
            ipAddress = parts.first!
            port = NetworkPort(parts.last!)
          }
        } else {
          #if os(macOS)
            let parts: [String] = remoteEndpoint?.components(separatedBy: ".") ?? []
            if parts.count != 2 {
              return
            }
            let noPort = parts.first!
            port = NetworkPort(parts.last!)
            if IPv6Address(noPort) != nil {
              ipAddress = noPort
            }
          #endif
        }
      }
    }
  }

  public var shortDescription: String {
    [
      ipProtocol?.description,
      url ?? hostname ?? ipAddress ?? remoteEndpoint,
      bundleId,
    ]
    .compactMap { $0 }
    .joined(separator: " ")
  }
}

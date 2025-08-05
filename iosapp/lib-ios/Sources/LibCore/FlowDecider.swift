import Foundation
import GertieIOS
import NetworkExtension

public struct FilterFlow: Sendable {
  public var hostname: String?
  public var url: String?
  public var bundleId: String?
  public var flowType: FlowType?

  public var target: String? {
    self.hostname ?? self.url ?? self.bundleId
  }

  public init(
    hostname: String? = nil,
    url: String? = nil,
    bundleId: String? = nil,
    flowType: FlowType? = nil
  ) {
    self.hostname = hostname
    self.url = url
    self.bundleId = bundleId
    self.flowType = flowType
  }
}

public protocol FlowDecider {
  var protectionMode: ProtectionMode { get }
  var calendar: Calendar { get }
  var now: Date { get }
  func log(_ message: String)
  func debugLog(_ message: String)
}

public extension FlowDecider {
  func decideNewFlow(_ flow: FilterFlow) -> FlowVerdict {
    let verdict: FlowVerdict = if let rules = self.protectionMode.rules {
      rules.blocksFlow(flow) ? .drop : .allow
    } else {
      self.decideLockdownFlow(flow)
    }
    self.log("flow verdict: \(verdict.description), target: \(flow.target ?? "(nil)")")
    return verdict
  }

  func decideLockdownFlow(_ flow: FilterFlow) -> FlowVerdict {
    let components = self.calendar.dateComponents([.hour, .minute], from: self.now)
    if components.hour == 19, components.minute! >= 0, components.minute! <= 5 {
      return .allow
    }

    let allowedSuffixes = ["gertrude.app", "apple.com", "icloud.com", "icloud.net"]
    if flow.bundleId?.contains("com.netrivet.gertrude-ios.app") == true {
      return .allow
    } else if flow.bundleId?.contains("com.apple.mDNSResponder") == true {
      return .allow
    } else if flow.bundleId?.contains("com.apple.Preferences") == true {
      return .allow
    } else if flow.hostname == nil, flow.url == nil {
      return .allow
    } else if let hostname = flow.hostname {
      for suffix in allowedSuffixes {
        if hostname.hasSuffix(suffix) {
          return .allow
        }
      }
      return .drop
    } else if let url = flow.url {
      let withoutScheme = url.replacingOccurrences(of: "https://", with: "")
      let segments = withoutScheme.split(separator: "/")
      let derivedHostname = segments.first ?? ""
      for suffix in allowedSuffixes {
        if derivedHostname.hasSuffix(suffix) {
          return .allow
        }
      }
      return .drop
    } else {
      return .drop
    }
  }

  func toFilterFlow(_ flow: NEFilterFlow) -> FilterFlow {
    var hostname: String?
    var url: String?
    let bundleId: String? = flow.sourceAppIdentifier
    let flowType: FlowType?

    if let browserFlow = flow as? NEFilterBrowserFlow {
      flowType = .browser
      url = browserFlow.url?.absoluteString
      self.debugLog("handle new BROWSER flow: \(String(describing: browserFlow))")
    } else if let socketFlow = flow as? NEFilterSocketFlow {
      flowType = .socket
      hostname = socketFlow.remoteHostname
      self.debugLog("handle new SOCKET flow: \(String(describing: socketFlow))")
    } else {
      flowType = nil
      self.debugLog("flow is NEITHER subclass id: \(String(describing: flow.identifier))")
    }
    return FilterFlow(
      hostname: hostname,
      url: url,
      bundleId: bundleId,
      flowType: flowType
    )
  }
}

public enum FlowVerdict {
  case allow
  case drop
  case needRules

  public var description: String {
    switch self {
    case .allow: "ALLOW"
    case .drop: "DROP"
    case .needRules: "NEED RULES"
    }
  }
}

// conformances

extension FlowVerdict: Equatable, Sendable {}

#if !os(iOS)
  class NEFilterBrowserFlow: NEFilterFlow {
    var request: URLRequest? { nil }
    var response: URLResponse? { nil }
    var parentURL: URL? { nil }
  }

  extension NEFilterFlow {
    var sourceAppIdentifier: String? { nil }
  }
#endif

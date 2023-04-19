import Foundation
import Shared

public struct BlockedRequest: Equatable, Codable, Sendable {
  public let url: String?
  public let hostname: String?
  public let ipAddress: String?
  public let appBundleId: String?
  public let ipProtocol: IpProtocol?

  public init(
    url: String? = nil,
    hostname: String? = nil,
    ipAddress: String? = nil,
    appBundleId: String? = nil,
    ipProtocol: IpProtocol? = nil
  ) {
    self.url = url
    self.hostname = hostname
    self.ipAddress = ipAddress
    self.appBundleId = appBundleId
    self.ipProtocol = ipProtocol
  }
}

public extension FilterFlow {
  var blockedRequest: BlockedRequest {
    BlockedRequest(
      url: url,
      hostname: hostname,
      ipAddress: ipAddress,
      appBundleId: bundleId,
      ipProtocol: ipProtocol
    )
  }
}

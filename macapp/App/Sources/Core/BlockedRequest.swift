import Foundation
import Gertie

public struct BlockedRequest: Equatable, Codable, Sendable {
  public let id: UUID
  public let time: Date
  public let app: AppDescriptor
  public let url: String?
  public let hostname: String?
  public let ipAddress: String?
  public let ipProtocol: IpProtocol?

  public init(
    id: UUID = UUID(),
    time: Date = Date(),
    app: AppDescriptor,
    url: String? = nil,
    hostname: String? = nil,
    ipAddress: String? = nil,
    ipProtocol: IpProtocol? = nil,
  ) {
    self.id = id
    self.time = time
    self.app = app
    self.url = url
    self.hostname = hostname
    self.ipAddress = ipAddress
    self.ipProtocol = ipProtocol
  }
}

public extension FilterFlow {
  func blockedRequest(
    id: UUID = .init(),
    time: Date = .init(),
    app: AppDescriptor,
  ) -> BlockedRequest {
    BlockedRequest(
      id: id,
      time: time,
      app: app,
      url: url,
      hostname: hostname,
      ipAddress: ipAddress,
      ipProtocol: ipProtocol,
    )
  }
}

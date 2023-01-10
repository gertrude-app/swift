import Duet
import Shared

final class NetworkDecision: Codable {
  var id: Id
  var deviceId: Device.Id
  var responsibleKeyId: Key.Id?
  var verdict: NetworkDecisionVerdict
  var reason: NetworkDecisionReason
  var ipProtocolNumber: Int?
  var hostname: String?
  var ipAddress: String?
  var url: String?
  var appBundleId: String?
  var count: Int
  var createdAt: Date

  var device = Parent<Device>.notLoaded
  var responsibleKey = OptionalParent<Key>.notLoaded

  var ipProtocol: IpProtocol? {
    if let number = ipProtocolNumber {
      return IpProtocol(Int32(number))
    }
    return nil
  }

  var reasonDescription: String {
    reason.description
  }

  var target: String? {
    url ?? hostname ?? ipAddress
  }

  init(
    id: Id = .init(),
    deviceId: Device.Id,
    responsibleKeyId: Key.Id? = nil,
    verdict: NetworkDecisionVerdict,
    reason: NetworkDecisionReason,
    count: Int = 1,
    ipProtocolNumber: Int? = nil,
    hostname: String? = nil,
    ipAddress: String? = nil,
    url: String? = nil,
    appBundleId: String? = nil,
    createdAt: Date
  ) {
    self.id = id
    self.deviceId = deviceId
    self.responsibleKeyId = responsibleKeyId
    self.verdict = verdict
    self.reason = reason
    self.count = count
    self.ipProtocolNumber = ipProtocolNumber
    self.hostname = hostname
    self.ipAddress = ipAddress
    self.url = url
    self.appBundleId = appBundleId
    self.createdAt = createdAt
  }
}

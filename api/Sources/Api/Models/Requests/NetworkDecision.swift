import Duet
import Shared

final class NetworkDecision: Codable {
  var id: Id
  var deviceId: Device.Id
  var responsibleKeyId: Key.Id?
  var verdict: Verdict
  var reason: Reason
  var ipProtocolNumber: Int?
  var hostname: String?
  var ipAddress: String?
  var url: String?
  var appBundleId: String?
  var count: Int
  var createdAt: Date
  var appDescriptor: AppDescriptor?

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
    verdict: Verdict,
    reason: Reason,
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

// extensions

extension NetworkDecision {
  enum Verdict: String, Codable, Equatable, CaseIterable {
    case block
    case allow
  }

  enum Reason: String, Codable, Equatable, CaseIterable, CustomStringConvertible {
    case systemUser
    case userIsExempt
    case missingKeychains
    case missingUserId
    case defaultNotAllowed
    case ipAllowed
    case domainAllowed
    case pathAllowed
    case fileExtensionAllowed
    case appBlocked
    case fromGertrudeApp
    case appUnrestricted
    case dns
    case nonDnsUdp
    case systemUiServerInternal
    case filterSuspended

    var description: String {
      switch self {
      case .defaultNotAllowed:
        return "no keychain allowed it"
      case .missingUserId:
        return "a mac user id for the request could not be determined"
      case .missingKeychains:
        return "no keys for the mac user were found"
      case .ipAllowed:
        return "a keychain allowed the IP address"
      case .domainAllowed:
        return "a keychain allowed the domain"
      case .pathAllowed:
        return "a keychain allowed the path"
      case .fileExtensionAllowed:
        return "a keychain allowed the file extension"
      case .appBlocked:
        return "the user blocked the app from any network access"
      case .appUnrestricted:
        return "a keychain granted the app unrestricted network access"
      case .fromGertrudeApp:
        return "the request came from the Gertie app"
      case .dns:
        return "all DNS requests are allowed"
      case .nonDnsUdp:
        return "all UDP requests (except DNS) are blocked"
      case .systemUser:
        return "the request came from an internal operating system user"
      case .userIsExempt:
        return "the request came from a user designated as exempt from blocking"
      case .filterSuspended:
        return "the filter was suspended at the time of the request"
      case .systemUiServerInternal:
        return
          "the request was made by an internal system networking utility related to the menu bar"
      }
    }
  }
}

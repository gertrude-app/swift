import Core

extension BlockedRequest {
  func mergeable(with other: BlockedRequest) -> Bool {
    if app.bundleId != other.app.bundleId {
      return false
    } else if ipProtocol != other.ipProtocol {
      return false
    } else if url != nil, url == other.url {
      return true
    } else if hostname != nil, hostname == other.hostname {
      return true
    } else if ipAddress != nil, ipAddress == other.ipAddress {
      return true
    }
    return false
  }
}

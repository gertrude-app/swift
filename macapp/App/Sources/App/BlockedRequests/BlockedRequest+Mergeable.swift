import Core

extension BlockedRequest {
  func mergeable(with newer: BlockedRequest) -> Bool {
    if newer.hostname != nil, self.hostname == nil {
      return false
    } else if newer.url != nil, self.url == nil {
      return false
    } else if self.app.bundleId != newer.app.bundleId {
      return false
    } else if self.ipProtocol != newer.ipProtocol {
      return false
    } else if self.url != nil, self.url == newer.url {
      return true
    } else if self.hostname != nil, self.hostname == newer.hostname {
      return true
    } else if self.ipAddress != nil, self.ipAddress == newer.ipAddress {
      return true
    }
    return false
  }
}

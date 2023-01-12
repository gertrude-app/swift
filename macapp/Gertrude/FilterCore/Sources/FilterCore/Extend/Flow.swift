import SharedCore
import NetworkExtension

public extension FilterFlow {
  init(_ rawFlow: NEFilterFlow, userId: uid_t? = nil) {
    self.init(url: rawFlow.url?.absoluteString, description: rawFlow.description)
    sourceAuditToken = rawFlow.sourceAppAuditToken
    self.userId = userId
  }
}

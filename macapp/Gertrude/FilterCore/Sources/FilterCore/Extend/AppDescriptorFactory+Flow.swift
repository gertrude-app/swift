import Shared
import SharedCore

public extension AppDescriptorFactory {
  func make(fromFlow flow: FilterFlow) -> AppDescriptor {
    make(bundleId: flow.bundleId ?? "", auditToken: flow.sourceAuditToken)
  }
}

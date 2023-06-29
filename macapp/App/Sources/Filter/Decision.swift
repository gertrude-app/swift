import Core
import Foundation
import Gertie

public protocol NetworkFilter: AppDescribing {
  associatedtype State: DecisionState
  var state: State { get }
  var security: SecurityClient { get }
}

public extension NetworkFilter {
  var appIdManifest: AppIdManifest { state.appIdManifest }
  func rootApp(fromAuditToken token: Data?) -> SecurityClient.RootApp {
    security.rootAppFromAuditToken(token)
  }
}

public protocol DecisionState {
  var userKeys: [uid_t: [FilterKey]] { get }
  var appIdManifest: AppIdManifest { get }
  var exemptUsers: Set<uid_t> { get }
  var suspensions: [uid_t: FilterSuspension] { get }
  var appCache: [String: AppDescriptor] { get }
}

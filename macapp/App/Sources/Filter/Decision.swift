import Core
import Foundation
import Gertie

public protocol NetworkFilter: AppDescribing {
  associatedtype State: DecisionState
  var state: State { get }
  var security: SecurityClient { get }
  var now: Date { get }
  var calendar: Calendar { get }
  func log(event: FilterLogs.Event)

  #if DEBUG
    // this is a bit of a compromise, because the FilterProxy was introduced
    // to extract the growing complexity of the logic in the FilterDataProvider
    // and now there are one too many layers for ergonomic testing, eventually
    // we should collapse them, but this should be safe and explicit for now
    var __TEST_MOCK_EARLY_DECISION: FilterDecision.FromUserId? { get set }
    var __TEST_MOCK_FLOW_DECISION: FilterDecision.FromFlow?? { get set }
  #endif
}

public extension NetworkFilter {
  var appIdManifest: AppIdManifest { state.appIdManifest }
  func rootApp(fromAuditToken token: Data?) -> SecurityClient.RootApp {
    security.rootAppFromAuditToken(token)
  }

  #if DEBUG
    var __TEST_MOCK_EARLY_DECISION: FilterDecision.FromUserId? { get { nil } set {} }
    var __TEST_MOCK_FLOW_DECISION: FilterDecision.FromFlow?? { get { nil } set {} }
  #endif
}

public protocol DecisionState {
  var userKeychains: [uid_t: [RuleKeychain]] { get }
  var userDowntime: [uid_t: Downtime] { get }
  var appIdManifest: AppIdManifest { get }
  var exemptUsers: Set<uid_t> { get }
  var suspensions: [uid_t: FilterSuspension] { get }
  var appCache: [String: AppDescriptor] { get }
  var macappsAliveUntil: [uid_t: Date] { get }
}

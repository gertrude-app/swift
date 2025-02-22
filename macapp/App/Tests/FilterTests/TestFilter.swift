import Core
import Dependencies
import Foundation
import Gertie

@testable import Filter

class TestFilter: NetworkFilter {
  struct State: DecisionState {
    var userKeychains: [uid_t: [RuleKeychain]] = [:]
    var userDowntime: [uid_t: Downtime] = [:]
    var appIdManifest = AppIdManifest()
    var exemptUsers: Set<uid_t> = []
    var suspensions: [uid_t: FilterSuspension] = [:]
    var appCache: [String: AppDescriptor] = [:]
    var macappsAliveUntil: [uid_t: Date] = [:]
  }

  var state = State()

  @Dependency(\.security) var security
  @Dependency(\.date.now) var now
  @Dependency(\.calendar) var calendar

  func appCache(get bundleId: String) -> AppDescriptor? {
    self.state.appCache[bundleId]
  }

  func appCache(insert: AppDescriptor, for bundleId: String) {
    self.state.appCache[bundleId] = insert
  }

  static func scenario(
    userIdFromAuditToken userId: uid_t? = 502,
    userKeychains: [uid_t: [RuleKeychain]] = [502: [.mock]],
    userDowntime: [uid_t: PlainTimeWindow] = [:],
    macappsAliveUntil: [uid_t: Date] = [502: .distantFuture, 503: .distantFuture],
    date: Dependencies.DateGenerator = .init { Date() },
    appIdManifest: AppIdManifest = .init(
      apps: ["chrome": ["com.chrome"]],
      displayNames: ["chrome": "Chrome"],
      categories: ["browser": ["chrome"]]
    ),
    exemptUsers: Set<uid_t> = [],
    suspensions: [uid_t: FilterSuspension] = [:]
  ) -> TestFilter {
    withDependencies {
      $0.security.userIdFromAuditToken = { token in
        token.flatMap { _ in userId }
      }
      $0.date = date
      $0.calendar = Calendar(identifier: .gregorian)
    } operation: {
      let filter = TestFilter()
      filter.state = State(
        userKeychains: userKeychains,
        userDowntime: userDowntime.mapValues { Downtime(window: $0) },
        appIdManifest: appIdManifest,
        exemptUsers: exemptUsers,
        suspensions: suspensions,
        macappsAliveUntil: macappsAliveUntil
      )
      return filter
    }
  }

  func log(event: FilterLogs.Event) {}
}

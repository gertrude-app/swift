import Core
import Dependencies
import Foundation
import Shared

@testable import Filter

struct TestFilter: NetworkFilter {
  struct State: DecisionState {
    var userKeys: [uid_t: [FilterKey]] = [:]
    var appIdManifest = AppIdManifest()
    var exemptUsers: Set<uid_t> = []
    var suspensions: [uid_t: FilterSuspension] = [:]
  }

  var state = State()

  @Dependency(\.security) var security

  static func scenario(
    userId: uid_t? = 502,
    userKeys: [uid_t: [FilterKey]] = [:],
    appIdManifest: AppIdManifest = AppIdManifest(),
    exemptUsers: Set<uid_t> = [],
    suspensions: [uid_t: FilterSuspension] = [:]
  ) -> TestFilter {
    withDependencies {
      $0.security.userIdFromAuditToken = {
        token in token.flatMap { _ in userId }
      }
    } operation: {
      var filter = TestFilter()
      filter.state = State(
        userKeys: userKeys,
        appIdManifest: appIdManifest,
        exemptUsers: exemptUsers,
        suspensions: suspensions
      )
      return filter
    }
  }
}

import Core
import Dependencies
import Foundation
import Gertie

@testable import Filter

class TestFilter: NetworkFilter {
  struct State: DecisionState {
    var userKeys: [uid_t: [FilterKey]] = [:]
    var appIdManifest = AppIdManifest()
    var exemptUsers: Set<uid_t> = []
    var suspensions: [uid_t: FilterSuspension] = [:]
    var appCache: [String: AppDescriptor] = [:]
  }

  var state = State()

  @Dependency(\.security) var security

  func appCache(get bundleId: String) -> AppDescriptor? {
    state.appCache[bundleId]
  }

  func appCache(insert: AppDescriptor, for bundleId: String) {
    state.appCache[bundleId] = insert
  }

  static func scenario(
    userIdFromAuditToken userId: uid_t? = 502,
    userKeys: [uid_t: [FilterKey]] = [502: [.mock]],
    appIdManifest: AppIdManifest = .init(
      apps: ["chrome": ["com.chrome"]],
      displayNames: ["chrome": "Chrome"],
      categories: ["browser": ["chrome"]]
    ),
    exemptUsers: Set<uid_t> = [],
    suspensions: [uid_t: FilterSuspension] = [:]
  ) -> TestFilter {
    withDependencies {
      $0.security.userIdFromAuditToken = {
        token in token.flatMap { _ in userId
        }
      }
    } operation: {
      let filter = TestFilter()
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

extension FilterKey {
  static let mock = FilterKey(
    id: .init(),
    key: .skeleton(scope: .bundleId("com.whitelisted.widget"))
  )
}

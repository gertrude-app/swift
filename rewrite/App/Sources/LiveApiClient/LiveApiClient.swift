import Dependencies
import Foundation
import MacAppRoute
import Models

extension ApiClient: DependencyKey {
  public static let liveValue = Self(
    connectUser: { input in
      User(fromPairQL: try await output(
        from: ConnectUser.self,
        withUnauthed: .connectUser(input)
      ))
    },
    clearUserToken: { await userToken.setValue(nil) },
    createUnlockRequests: { input in
      try await output(
        from: CreateUnlockRequests_v2.self,
        with: .createUnlockRequests_v2(input)
      )
    },
    getAdminAccountStatus: {
      try await output(
        from: GetAccountStatus.self,
        with: .getAccountStatus
      ).status
    },
    latestAppVersion: { input in
      try await output(
        from: LatestAppVersion.self,
        withUnauthed: .latestAppVersion(input)
      )
    },
    refreshRules: { input in
      try await output(
        from: RefreshRules.self,
        with: .refreshRules(input)
      )
    },
    setEndpoint: { await endpoint.setValue($0) },
    setUserToken: { await userToken.setValue($0) }
  )
}

internal let userToken = ActorIsolated<User.Token?>(nil)
#if DEBUG
  internal let endpoint = ActorIsolated<URL>(.init(string: "http://127.0.0.1:8080/pairql")!)
#else
  internal let endpoint = ActorIsolated<URL>(.init(string: "https://api.gertrude.app/pairql")!)
#endif

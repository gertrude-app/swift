import Dependencies
import Foundation
import MacAppRoute
import Models

extension ApiClient: DependencyKey {
  public static let liveValue = Self(
    clearUserToken: { await userToken.setValue(nil) },
    connectUser: { input in
      User(fromPairQL: try await output(
        from: ConnectUser.self,
        withUnauthed: .connectUser(input)
      ))
    },
    createKeystrokeLines: { input in
      // always produces `.success` if it doesn't throw
      _ = try await output(
        from: CreateKeystrokeLines.self,
        with: .createKeystrokeLines(input)
      )
    },
    createSuspendFilterRequest: { input in
      // always produces `.success` if it doesn't throw
      _ = try await output(
        from: CreateSuspendFilterRequest.self,
        with: .createSuspendFilterRequest(input)
      )
    },
    createUnlockRequests: { input in
      // always produces `.success` if it doesn't throw
      _ = try await output(
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
    setUserToken: { await userToken.setValue($0) },
    uploadScreenshot: { jpegData, width, height in
      let signed = try await output(
        from: CreateSignedScreenshotUpload.self,
        with: .createSignedScreenshotUpload(.init(width: width, height: height))
      )

      var request = URLRequest(url: signed.uploadUrl, cachePolicy: .reloadIgnoringCacheData)
      request.httpMethod = "PUT"
      request.addValue("public-read", forHTTPHeaderField: "x-amz-acl")
      request.addValue("image/jpeg", forHTTPHeaderField: "Content-Type")

      return try await withCheckedThrowingContinuation { continuation in
        URLSession.shared.uploadTask(with: request, from: jpegData) { data, response, error in
          if let error {
            continuation.resume(throwing: error)
            return
          }
          guard let data, let response else {
            struct MissingDataOrResponse: Error {}
            continuation.resume(throwing: MissingDataOrResponse())
            return
          }
          continuation.resume(returning: signed.webUrl)
        }.resume()
      }
    }
  )
}

internal let userToken = ActorIsolated<User.Token?>(nil)
#if DEBUG
  internal let endpoint = ActorIsolated<URL>(.init(string: "http://127.0.0.1:8080/pairql")!)
#else
  internal let endpoint = ActorIsolated<URL>(.init(string: "https://api.gertrude.app/pairql")!)
#endif

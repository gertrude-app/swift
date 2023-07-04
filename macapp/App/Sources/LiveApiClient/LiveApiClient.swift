import ClientInterfaces
import Dependencies
import Foundation
import Gertie
import MacAppRoute

extension ApiClient: DependencyKey {
  public static let liveValue = Self(
    clearUserToken: { await userToken.setValue(nil) },
    connectUser: { input in
      try await output(
        from: ConnectUser.self,
        withUnauthed: .connectUser(input)
      )
    },
    createKeystrokeLines: { input in
      guard await accountActive.value else { return }
      // always produces `.success` if it doesn't throw
      _ = try await output(
        from: CreateKeystrokeLines.self,
        with: .createKeystrokeLines(input)
      )
    },
    createSuspendFilterRequest: { input in
      guard await accountActive.value else { return }
      // always produces `.success` if it doesn't throw
      _ = try await output(
        from: CreateSuspendFilterRequest.self,
        with: .createSuspendFilterRequest(input)
      )
    },
    createUnlockRequests: { input in
      guard await accountActive.value else { return }
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
    logUnexpectedError: { input in
      _ = try? await output(
        from: LogUnexpectedError.self,
        withUnauthed: .logUnexpectedError(input)
      )
    },
    recentAppVersions: {
      try await output(
        from: RecentAppVersions.self,
        withUnauthed: .recentAppVersions
      )
    },
    refreshRules: { input in
      guard await accountActive.value else { throw Error.accountInactive }
      return try await output(
        from: RefreshRules.self,
        with: .refreshRules(input)
      )
    },
    setAccountActive: { await accountActive.setValue($0) },
    setUserToken: { await userToken.setValue($0) },
    uploadScreenshot: { jpegData, width, height, createdAt in
      guard await accountActive.value else { throw Error.accountInactive }
      let signed = try await output(
        from: CreateSignedScreenshotUpload.self,
        with: .createSignedScreenshotUpload(.init(
          width: width,
          height: height,
          createdAt: createdAt
        ))
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
            continuation.resume(throwing: Error.missingDataOrResponse)
            return
          }
          continuation.resume(returning: signed.webUrl)
        }.resume()
      }
    },
    userData: {
      try await output(
        from: GetUserData.self,
        with: .getUserData
      )
    }
  )
}

internal let accountActive = ActorIsolated<Bool>(true)
internal let userToken = ActorIsolated<UUID?>(nil)

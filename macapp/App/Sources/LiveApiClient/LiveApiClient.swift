import ClientInterfaces
import Dependencies
import Foundation
import Gertie
import MacAppRoute

extension ApiClient: @retroactive DependencyKey {
  public static let liveValue = Self(
    checkIn: { input in
      try await output(
        from: CheckIn_v2.self,
        with: .checkIn_v2(input)
      )
    },
    clearUserToken: {
      userToken.setValue(nil)
    },
    connectUser: { input in
      try await output(
        from: ConnectUser.self,
        withUnauthed: .connectUser(input)
      )
    },
    createKeystrokeLines: { input in
      guard accountActive.value else { return }
      // always produces `.success` if it doesn't throw
      _ = try await output(
        from: CreateKeystrokeLines.self,
        with: .createKeystrokeLines(input)
      )
    },
    createSuspendFilterRequest: { input in
      guard accountActive.value else { return .init() }
      return try await output(
        from: CreateSuspendFilterRequest_v2.self,
        with: .createSuspendFilterRequest_v2(input)
      )
    },
    createUnlockRequests: { input in
      guard accountActive.value else { return [] }
      return try await output(
        from: CreateUnlockRequests_v3.self,
        with: .createUnlockRequests_v3(input)
      )
    },
    getUserToken: {
      userToken.value
    },
    logFilterEvents: { input in
      guard accountActive.value else { return }
      _ = try? await output(
        from: LogFilterEvents.self,
        with: .logFilterEvents(input)
      )
    },
    logInterestingEvent: { input in
      _ = try? await output(
        from: LogInterestingEvent.self,
        withUnauthed: .logInterestingEvent(input)
      )
    },
    logSecurityEvent: { input, bufferedToken in
      // sleep allows us to log events possibly before token/account resolved
      if input.event == "appLaunched" {
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
      } else {
        try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
      }
      guard accountActive.value else { return }
      let currentToken = userToken.value
      // NB: prefer bufferedToken
      let token = bufferedToken ?? currentToken
      guard token != nil else { return }
      _ = try? await output(
        from: LogSecurityEvent.self,
        with: .logSecurityEvent(input),
        using: token
      )
    },
    recentAppVersions: {
      try await output(
        from: RecentAppVersions.self,
        withUnauthed: .recentAppVersions
      )
    },
    reportBrowsers: { input in
      guard accountActive.value else { return }
      _ = try await output(
        from: ReportBrowsers.self,
        with: .reportBrowsers(input)
      )
    },
    setAccountActive: { accountActive.setValue($0) },
    setUserToken: { userToken.setValue($0) },
    trustedNetworkTimestamp: {
      try await output(
        from: TrustedTime.self,
        withUnauthed: .trustedTime
      )
    },
    uploadScreenshot: { data in
      guard accountActive.value else { throw Error.accountInactive }
      let signed = try await output(
        from: CreateSignedScreenshotUpload.self,
        with: .createSignedScreenshotUpload(.init(
          width: data.width,
          height: data.height,
          filterSuspended: data.filterSuspended,
          createdAt: data.createdAt
        ))
      )

      var request = URLRequest(url: signed.uploadUrl, cachePolicy: .reloadIgnoringCacheData)
      request.httpMethod = "PUT"
      request.addValue("public-read", forHTTPHeaderField: "x-amz-acl")
      request.addValue("image/jpeg", forHTTPHeaderField: "Content-Type")

      return try await withCheckedThrowingContinuation { continuation in
        URLSession.shared.uploadTask(with: request, from: data.image) { data, response, error in
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
    }
  )
}

internal let accountActive = ActorIsolated<Bool>(true)
internal let userToken = ActorIsolated<UUID?>(nil)

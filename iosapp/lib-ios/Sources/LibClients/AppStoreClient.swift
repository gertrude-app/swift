import Dependencies
import DependenciesMacros

#if os(iOS)
  import StoreKit
  import UIKit
#endif

@DependencyClient
public struct AppStoreClient: Sendable {
  public var requestRating: @Sendable () async -> Void
  public var requestReview: @Sendable () async -> Void
}

extension AppStoreClient: DependencyKey {
  #if os(iOS)
    public static let liveValue = AppStoreClient(
      requestRating: {
        if let scene = await UIApplication.shared.connectedScenes.first as? UIWindowScene {
          await SKStoreReviewController.requestReview(in: scene)
        }
      },
      requestReview: {
        let url = "https://apps.apple.com/app/id6736368820?action=write-review"
        if let writeReviewURL = URL(string: url) {
          Task { @MainActor in
            await UIApplication.shared.open(writeReviewURL)
          }
        }
      },
    )
  #else
    public static let liveValue = AppStoreClient(
      requestRating: {},
      requestReview: {},
    )
  #endif
}

extension AppStoreClient: TestDependencyKey {
  public static let testValue = AppStoreClient()
}

public extension DependencyValues {
  var appStore: AppStoreClient {
    get { self[AppStoreClient.self] }
    set { self[AppStoreClient.self] = newValue }
  }
}

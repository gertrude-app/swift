import Dependencies
import DependenciesMacros
import Foundation
import GertieIOS

@DependencyClient
public struct FilterClient: Sendable {
  // NB: FilterControProvider has a `notifyRulesChanged()`, which we expose
  // on the ControllerProxy, but we can't access that from the main app process
  // so this allows the App to instruct the Filter to reload its rules
  public var notifyRulesChanged: @Sendable () async throws -> Void
  public var suspend: @Sendable (_ until: Date) async -> Void
  public var resume: @Sendable () async -> Void
}

extension FilterClient: DependencyKey {
  public static var liveValue: FilterClient {
    FilterClient(
      notifyRulesChanged: {
        await fireAndForget(url: .readRulesSentinel)
      },
      suspend: { expiration in
        @Dependency(\.storage) var storage
        storage.saveDate(expiration, forKey: .filterSuspensionExpirationKey)
        await fireAndForget(url: .suspendSentinel)
      },
      resume: {
        @Dependency(\.storage) var storage
        storage.removeObject(forKey: .filterSuspensionExpirationKey)
        await fireAndForget(url: .resumeSentinel)
      }
    )
  }
}

func fireAndForget(url: URL) async {
  var request = URLRequest(url: url)
  request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
  _ = try? await URLSession.shared.data(for: request)
}

extension URL {
  static let readRulesSentinel = URL(string: "https://read-rules.xpc.gertrude.app")!
  static let suspendSentinel = URL(string: "https://suspend-filter.xpc.gertrude.app")!
  static let resumeSentinel = URL(string: "https://resume-filter.xpc.gertrude.app")!
}

public extension DependencyValues {
  var filter: FilterClient {
    get { self[FilterClient.self] }
    set { self[FilterClient.self] = newValue }
  }
}

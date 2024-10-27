import Dependencies
import DependenciesMacros
import Foundation
import GertieIOS

@DependencyClient
public struct FilterClient: Sendable {
  // NB: FilterControProvider has a `notifyRulesChanged()` we could use
  // but it's not clear to me how we would make that controllable/testable
  // so we have our own message with a sentinal URL http request
  public var notifyRulesChanged: @Sendable () async throws -> Void
  public var sendFilterErrors: @Sendable () async throws -> Void
}

extension FilterClient: DependencyKey {
  public static var liveValue: FilterClient {
    FilterClient(
      notifyRulesChanged: {
        await fireAndForget(url: .readRulesSentinel)
      },
      sendFilterErrors: {
        @Dependency(\.device.vendorId) var vendorId
        await fireAndForget(url: .flushErr(.noRulesFound, for: vendorId))
        await fireAndForget(url: .flushErr(.rulesDecodeFailed, for: vendorId))
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
  static let readRulesSentinel = URL(string: "https://read-rules.gertrude.app")!

  static func flushErr(_ error: FilterError, for vendorId: UUID?) -> URL {
    var urlString = "\(String.gertrudeApi)/\(FilterError.urlSlug)/\(error.urlSlug)"
    if let vendorId {
      urlString += "/\(vendorId.uuidString.lowercased())"
    }
    return URL(string: urlString)!
  }
}

public extension DependencyValues {
  var filter: FilterClient {
    get { self[FilterClient.self] }
    set { self[FilterClient.self] = newValue }
  }
}

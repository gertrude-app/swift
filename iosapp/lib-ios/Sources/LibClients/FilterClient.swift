import Dependencies
import DependenciesMacros
import Foundation
import GertieIOS
import LibCore

@DependencyClient
public struct FilterClient: Sendable {
  public enum Notification: Sendable {
    case rulesChanged
    case refreshRules
    case dumpLogs
  }

  /// send "notifications" via special sentinal http requests, from app to filter
  public var send: @Sendable (_ notification: Notification) async throws -> Void
}

extension FilterClient: DependencyKey {
  public static var liveValue: FilterClient {
    FilterClient(
      send: { notification in
        switch notification {
        case .dumpLogs:
          await fireAndForget(
            url: URL(string: "https://\(MagicStrings.dumpLogsSentinalHostname)")!,
          )
        case .rulesChanged:
          await fireAndForget(
            url: URL(string: "https://\(MagicStrings.readRulesSentinalHostname)")!,
          )
        case .refreshRules:
          await fireAndForget(
            url: URL(string: "https://\(MagicStrings.refreshRulesSentinalHostname)")!,
          )
        }
      },
    )
  }
}

func fireAndForget(url: URL) async {
  var request = URLRequest(url: url)
  request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
  _ = try? await URLSession.shared.data(for: request)
}

public extension DependencyValues {
  var filter: FilterClient {
    get { self[FilterClient.self] }
    set { self[FilterClient.self] = newValue }
  }
}

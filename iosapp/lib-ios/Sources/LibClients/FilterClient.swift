import Dependencies
import DependenciesMacros
import Foundation
import GertieIOS
import LibCore

@DependencyClient
public struct FilterClient: Sendable {
  public enum Notification {
    case rulesChanged
    case dumpLogs
  }

  // NB: FilterControProvider has a `notifyRulesChanged()`, which we expose
  // on the ControllerProxy, but we can't access that from the main app process
  // so this allows the App to instruct the Filter to reload its rules
  public var send: @Sendable (_ notification: Notification) async throws -> Void
}

extension FilterClient: DependencyKey {
  public static var liveValue: FilterClient {
    FilterClient(
      send: { notification in
        switch notification {
        case .dumpLogs:
          await fireAndForget(
            url: URL(string: "https://\(MagicStrings.readRulesSentinalHostname)")!
          )
        case .rulesChanged:
          await fireAndForget(
            url: URL(string: "https://\(MagicStrings.dumpLogsSentinalHostname)")!
          )
        }
      }
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

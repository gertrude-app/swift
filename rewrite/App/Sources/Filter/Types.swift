import Core
import Foundation
import Shared

public extension XPCEvent {
  enum Filter: Equatable, Sendable {
    public enum MessageFromApp: Sendable, Equatable {
      case userRules(userId: uid_t, keys: [FilterKey], manifest: AppIdManifest)
      case setBlockStreaming(enabled: Bool, userId: uid_t)
    }

    case receivedAppMessage(MessageFromApp)
    case decodingAppMessageDataFailed(fn: String, type: String, error: String)
  }
}

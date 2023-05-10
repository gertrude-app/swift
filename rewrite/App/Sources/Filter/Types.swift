import Core
import Foundation
import Shared
import TaggedTime

public extension XPCEvent {
  enum Filter: Equatable, Sendable {
    public enum MessageFromApp: Sendable, Equatable {
      case userRules(userId: uid_t, keys: [FilterKey], manifest: AppIdManifest)
      case setBlockStreaming(enabled: Bool, userId: uid_t)
      case disconnectUser(userId: uid_t)
      case endFilterSuspension(userId: uid_t)
      case suspendFilter(userId: uid_t, duration: Seconds<Int>)
    }

    case receivedAppMessage(MessageFromApp)
    case decodingAppMessageDataFailed(fn: String, type: String, error: String)
  }
}

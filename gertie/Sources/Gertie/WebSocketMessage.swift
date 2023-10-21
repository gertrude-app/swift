import Foundation
import TaggedTime

public enum WebSocketMessage {
  public enum FromApiToApp: Codable, Equatable, Sendable {
    case currentFilterStateRequested
    case filterSuspensionRequestDecided(decision: FilterSuspensionDecision, comment: String?)
    case unlockRequestUpdated(status: RequestStatus, target: String, parentComment: String?)
    case userDeleted
    case userUpdated

    // deprecated as of v2.1.0 - when that is MSV, remove these cases
    case suspendFilter(for: Seconds<Int>, parentComment: String?)
    case suspendFilterRequestDenied(parentComment: String?)
  }

  public enum FromAppToApi: Codable, Equatable {
    case currentFilterState(UserFilterState)
    case goingOffline
  }

  public enum ErrorCode: UInt16 {
    case userTokenNotFound = 4999
  }
}

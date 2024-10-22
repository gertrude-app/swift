import Foundation
import TaggedTime

public enum WebSocketMessage {
  public enum FromApiToApp: Codable, Equatable, Sendable {
    case currentFilterStateRequested
    case userDeleted
    case userUpdated
    case filterSuspensionRequestDecided_v2(
      id: UUID,
      decision: FilterSuspensionDecision,
      comment: String?
    )
    case unlockRequestUpdated_v2(
      id: UUID,
      status: RequestStatus,
      target: String,
      comment: String?
    )

    // deprecated as of v2.4.0 - when that is MSV, remove these cases
    case unlockRequestUpdated(status: RequestStatus, target: String, parentComment: String?)
    case filterSuspensionRequestDecided(decision: FilterSuspensionDecision, comment: String?)

    // deprecated as of v2.1.0 - when that is MSV, remove these cases
    case suspendFilter(for: Seconds<Int>, parentComment: String?)
    case suspendFilterRequestDenied(parentComment: String?)
  }

  public enum FromAppToApi: Codable, Equatable {
    case currentFilterState(FilterState.WithoutTimes)
    case goingOffline
  }

  public enum ErrorCode: UInt16 {
    case userTokenNotFound = 4999
  }
}

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
  }

  public enum FromAppToApi: Codable, Equatable {
    case currentFilterState(FilterState.WithoutTimes)
    case goingOffline
  }

  public enum ErrorCode: UInt16 {
    case userTokenNotFound = 4999
  }
}

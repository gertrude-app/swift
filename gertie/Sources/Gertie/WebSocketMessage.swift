import Foundation
import TaggedTime

public enum WebSocketMessage {
  public enum FromApiToApp: Codable, Equatable, Sendable {
    case currentFilterStateRequested
    case suspendFilter(for: Seconds<Int>, parentComment: String?)
    case suspendFilterRequestDenied(parentComment: String?)
    case unlockRequestUpdated(status: RequestStatus, target: String, parentComment: String?)
    case userDeleted
    case userUpdated
  }

  public enum FromAppToApi: Codable {
    case currentFilterState(UserFilterState)
    case goingOffline
  }

  public enum ErrorCode: UInt16 {
    case userTokenNotFound = 4999
  }
}

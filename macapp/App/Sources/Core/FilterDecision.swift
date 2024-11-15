import Foundation

public enum FilterDecision: Equatable, Sendable {
  public enum FromFlow: Equatable, Sendable {
    public enum BlockReason: Equatable, Sendable {
      case missingUserId
      case noUserKeys
      case defaultNotAllowed
    }

    public enum AllowReason: Equatable, Sendable {
      case dnsRequest
      case fromGertrudeApp
      case filterSuspended
      case systemUiServerInternal
      case permittedByKey(UUID)
    }

    case block(BlockReason)
    case allow(AllowReason)
  }

  public enum FromUserId: Equatable, Sendable {
    public enum Reason: Equatable, Sendable {
      case missingUserId
      case systemUser(uid_t)
      case exemptUser(uid_t)
      case filterSuspended(uid_t)
    }

    case block(Reason)
    case allow(Reason)
    case blockDuringDowntime(uid_t)
    case none(uid_t)
  }

  case fromFlow(FromFlow)
  case fromUserId(FromUserId)
}

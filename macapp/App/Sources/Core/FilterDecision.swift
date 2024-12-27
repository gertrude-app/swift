import Foundation

public enum FilterDecision: Equatable, Sendable {
  public enum FromFlow: Equatable, Sendable {
    public enum BlockReason: Equatable, Sendable {
      case missingUserId
      case noUserKeys
      case defaultNotAllowed
      case urlMessage(XPC.URLMessage)
      case macappAWOL(uid_t)
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
    public enum BlockReason: Equatable, Sendable {
      case missingUserId
    }

    public enum AllowReason: Equatable, Sendable {
      case systemUser(uid_t)
      case exemptUser(uid_t)
      case filterSuspended(uid_t)
    }

    case block(BlockReason)
    case allow(AllowReason)
    case blockDuringDowntime(uid_t)
    case none(uid_t)
  }

  case fromFlow(FromFlow)
  case fromUserId(FromUserId)
}

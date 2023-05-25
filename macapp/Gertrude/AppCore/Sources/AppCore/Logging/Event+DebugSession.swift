import Gertie
import SharedCore

public extension AppLogEvent {
  enum DebugSessionEvent: LogMessagable {
    case started(DebugSession)
    case ended(DebugSession)

    public var logMessage: Log.Message {
      switch self {
      case .started(let session):
        return .info(
          "started",
          .primary([
            "session_id": session.id.lowercased,
            "expiration": session.expiration.isoString,
          ])
        )
      case .ended(let session):
        return .info("ended", .primary(["session_id": session.id.lowercased]))
      }
    }
  }
}

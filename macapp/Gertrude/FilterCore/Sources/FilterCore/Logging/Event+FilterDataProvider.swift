import Shared
import SharedCore
import NetworkExtension

public enum FilterDecisionEvent: LogMessagable {
  case devOnlyXcodeBuildRequestAllowed

  public var logMessage: Log.Message {
    switch self {
    case .devOnlyXcodeBuildRequestAllowed:
      return .warn("allowing dev-only xcode build request")
    }
  }
}

public enum FilterDecisionDebugEvent: LogMessagable {
  case made(MadeDecisionEvent)
  case deferred(Log.Meta)

  public var logMessage: Log.Message {
    switch self {
    case .made(let decision):
      return "made" |> decision.logMessage
    case .deferred(let meta):
      return .debug("deferred until outbound data seen", meta)
    }
  }
}

public extension FilterDecisionDebugEvent {
  enum MadeDecisionEvent: LogMessagable {
    case earlyFromUserId(EarlyUserIdEvent)
    case beforeSeeingOutboundData(Log.Meta)
    case afterSeeingOutboundData(Log.Meta, String)

    public var logMessage: Log.Message {
      switch self {
      case .earlyFromUserId(let event):
        return "early from user id" |> event.logMessage
      case .beforeSeeingOutboundData(let meta):
        return .debug("before seeing outbound data", meta)
      case .afterSeeingOutboundData(let meta, let data):
        return .debug("after seeing outbound data", meta + [
          "filter_decision.outbound_data": .string(data),
        ])
      }
    }
  }
}

public extension FilterDecisionDebugEvent.MadeDecisionEvent {
  enum EarlyUserIdEvent: LogMessagable {
    case allowSystemUser(Log.Meta)
    case allowExemptUser(Log.Meta)
    case filterSuspended(Log.Meta)
    case unexpectedMissingUserId(Log.Meta)
    case unexpectedCondition(Log.Meta)

    public var logMessage: Log.Message {
      switch self {
      case .allowExemptUser(let meta):
        return .debug("allow exempt user", meta)
      case .allowSystemUser(let meta):
        return .debug("allow system user", meta)
      case .filterSuspended(let meta):
        return .debug("user in unrestricted filter suspension", meta)
      case .unexpectedMissingUserId(let meta):
        return .error("unexpected missing user id", meta)
      case .unexpectedCondition(let meta):
        return .error("unexpected logic condition", meta)
      }
    }
  }
}

public enum FilterDataProviderEvent: LogMessagable {
  case filterStarted
  case filterStopped
  case error(String, Error?)

  public var logMessage: Log.Message {
    switch self {
    case .filterStarted:
      return .notice("filter stopped")
    case .filterStopped:
      return .notice("filter started")
    case .error(let msg, let error):
      return .error(msg, .error(error))
    }
  }
}

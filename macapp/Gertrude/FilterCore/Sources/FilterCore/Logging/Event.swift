import Foundation
import Gertie
import SharedCore

public enum FilterLogEvent: LogMessagable {
  case filterStorage(FilterStorageEvent)
  case filterDecision(FilterDecisionEvent)
  case filterDataProvider(FilterDataProviderEvent)
  case receiveAppMessage(ReceiveAppMessageEvent)
  case xpcDelegate(FilterXPCDelegateEvent)
  case decodeError(Decodable.Type, String?)
  case encodeError(Encodable.Type)
  case encodeCountError(Encodable.Type, expected: Int, actual: Int)
  case decodeCountError(Encodable.Type, expected: Int, actual: Int)

  public var logMessage: Log.Message {
    switch self {
    case .filterStorage(let event):
      return "filter storage" |> event.logMessage
    case .filterDataProvider(let event):
      return "FilterDataProvider" |> event.logMessage
    case .filterDecision(let event):
      return "filter decision" |> event.logMessage
    case .receiveAppMessage(let event):
      return "(XPC) receive app message" |> event.logMessage
    case .xpcDelegate(let event):
      return "(XPC) listener delegate" |> event.logMessage
    case .decodeError(let type, let json):
      return .error(
        "json decode error",
        .primary(["decodable_type": "\(type)"]) + .json(json)
      )
    case .encodeError(let type):
      return .error("json encode error", .primary(["encodable_type": "\(type)"]))
    case .encodeCountError(let type, expected: let expected, actual: let actual):
      return .error(
        "json encode array length error",
        .primary([
          "encodable_type": "\(type)",
          "unencoded_count": "\(expected)",
          "encoded_count": "\(actual)",
        ])
      )
    case .decodeCountError(let type, expected: let expected, actual: let actual):
      return .error(
        "json decode array length error",
        .primary([
          "encodable_type": "\(type)",
          "unencoded_count": "\(expected)",
          "encoded_count": "\(actual)",
        ])
      )
    }
  }
}

public enum FilterDebugEvent: LogMessagable {
  case receiveAppMessage(ReceiveAppMessageDebugEvent)
  case filterDecision(FilterDecisionDebugEvent)
  public var logMessage: Log.Message {
    switch self {
    case .filterDecision(let event):
      return "filter decision" |> event.logMessage
    case .receiveAppMessage(let event):
      return "(XPC) receive app message" |> event.logMessage
    }
  }
}

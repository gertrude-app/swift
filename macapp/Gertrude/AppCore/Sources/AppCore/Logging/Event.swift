import Cocoa
import Gertie
import SharedCore

public enum AppLogEvent: LogMessagable {
  case event(GenericEvent)
  case filterController(FilterControllerEvent)
  case api(ApiClientEvent)
  case debugSession(DebugSessionEvent)
  case deviceStorage(DeviceStorageClientEvent)
  case screenshot(GenericEvent)
  case systemExtensionRequestDelegate(GenericEvent)
  case plugin(String, GenericEvent)
  case unexplainedAppError(AppError)
  case decodeError(Decodable.Type, String?)
  case encodeError(Encodable.Type)
  case encodeCountError(Encodable.Type, expected: Int, actual: Int)
  case decodeCountError(Encodable.Type, expected: Int, actual: Int)

  public var logMessage: Log.Message {
    switch self {
    case .event(let event):
      return event.logMessage
    case .debugSession(let event):
      return "debug session" |> event.logMessage
    case .deviceStorage(let event):
      return "device storage" |> event.logMessage
    case .filterController(let event):
      return "(XPC) (APP) FilterController" |> event.logMessage
    case .systemExtensionRequestDelegate(let event):
      return "system extension request delegate" |> event.logMessage
    case .unexplainedAppError(let appError):
      return .error("unexplained app error", .primary("\(~appError)"))
    case .screenshot(let event):
      return "screenshot" |> event.logMessage
    case .api(let event):
      return "api" |> event.logMessage
    case .decodeError(let type, let json):
      return .error(
        "json decode error",
        .primary(["decodable_type": "\(type)"]) + .json(json)
      )
    case .plugin(let name, let event):
      return "Plugin \(name)" |> event.logMessage
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

extension AppLogEvent: GenericEventHandler {
  public static func genericEvent(_ event: GenericEvent) -> AppLogEvent {
    .event(event)
  }
}

public enum AppDebugEvent: LogMessagable {
  case api(ApiClientDebugEvent)
  case unusableKeystroke(NSEvent, String?)

  public var logMessage: Log.Message {
    switch self {
    case .api(let event):
      return "api" |> event.logMessage
    case .unusableKeystroke(let event, let frontmostApp):
      return .debug("keylogging > unusable keystroke", [
        "meta.debug": .string("app=\(frontmostApp ?? "(nil)")\nevent=\(~event)"),
      ])
    }
  }
}

prefix func ~ (value: Any?) -> String {
  String(describing: value)
}

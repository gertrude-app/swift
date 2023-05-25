import MacAppRoute
import Gertie
import SharedCore
import XCore

public extension AppLogEvent {
  enum ApiClientEvent: LogMessagable, GenericEventHandler {
    case event(GenericEvent)
    case receivedResponse(String)
    case pqlError(String, PqlError)
    case genericError(String, Error)
    case inactiveAccountNoop(String)

    public static func genericEvent(_ event: GenericEvent) -> Self {
      .event(event)
    }

    public var logMessage: Log.Message {
      switch self {
      case .pqlError(let operation, let err):
        return .error("PairQL operation \(operation) error \(err.id)", [
          "meta.primary": .string(err.debugMessage),
          "meta.debug": .string("serverRequestId = \(err.requestId)"),
        ])

      case .receivedResponse(let operation):
        return .info("received PairQL response successfully, operation: \(operation)", [
          "meta.primary": .string("PairQL operation name = \(operation)"),
        ])

      case .genericError(let operation, let error):
        return .error("Api request for operation \(operation) failed with error", .error(error))

      case .inactiveAccountNoop(let methodName):
        return .info("call to \(methodName) skipped -- inactive account")

      case .event(let event):
        return event.logMessage
      }
    }
  }
}

public extension AppDebugEvent {
  enum ApiClientDebugEvent: LogMessagable {
    case receiveAppIdManifest(AppIdManifest)

    public var logMessage: Log.Message {
      switch self {
      case .receiveAppIdManifest(let manifest):
        return .debug("received AppIdManifest", ["json.raw": .init(try? JSON.encode(manifest))])
      }
    }
  }
}

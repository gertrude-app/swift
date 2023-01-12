import SharedCore

public extension AppLogEvent {
  enum FilterControllerEvent: LogMessagable, GenericEventHandler {
    case methodInvoked(String)
    case event(GenericEvent)

    public static func genericEvent(_ event: GenericEvent) -> Self {
      .event(event)
    }

    public var logMessage: Log.Message {
      switch self {
      case .methodInvoked(let method):
        return .debug("method \(method) invoked")
      case .event(let generic):
        return generic.logMessage
      }
    }
  }
}

import Shared
import SharedCore

public enum FilterXPCDelegateEvent: LogMessagable {
  case startListener
  case newConnection
  case invalidationHandlerInvoked
  case interruptionHandlerInvoked
  case remoteObjectProxyError(Error)

  public var logMessage: Log.Message {
    switch self {
    case .startListener:
      return .info("starting XPC listener")
    case .newConnection:
      return .info("new connection established")
    case .invalidationHandlerInvoked:
      return .warn("invalidation handler invoked")
    case .interruptionHandlerInvoked:
      return .warn("interruption handler invoked")
    case .remoteObjectProxyError(let error):
      return .error("error getting app receiver remote proxy", .error(error))
    }
  }
}

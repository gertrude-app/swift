import Gertie
import SharedCore

public extension AppLogEvent {
  enum DeviceStorageClientEvent: LogMessagable {
    case noDataFound
    case set(String, String)
    case get(String, String?)
    case delete(String, String?)
    case purgeAll

    public var logMessage: Log.Message {
      switch self {
      case .noDataFound:
        return .warn("no data found (expected on first app launch)")
      case .set(let key, let value):
        return .debug("set \(key)", .primary("value=\(value)"))
      case .get(let key, let value):
        return .debug("get \(key)", .primary("value=\(value ?? "(nil)")"))
      case .delete(let key, let oldValue):
        return .debug("delete \(key)", .primary("oldValue=\(oldValue ?? "(nil)")"))
      case .purgeAll:
        return .info("purge all")
      }
    }
  }
}

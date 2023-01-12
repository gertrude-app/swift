import Foundation
import SharedCore

struct AppWindowLogger: LoggerProtocol {
  weak var store: AppStore?

  func log(_ message: Log.Message) {
    DispatchQueue.main.async {
      store?.send(.receivedNewAppLog(message))
    }
  }
}

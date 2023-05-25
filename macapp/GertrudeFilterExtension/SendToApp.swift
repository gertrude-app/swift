import Combine
import Foundation
import os.log
import Gertie
import SharedCore
import XCore

struct SendToApp {
  static func batchedHoneycombLogs(_ logs: [Log.Message]) -> AnyPublisher<Bool, Never> {
    Future { promise in
      guard !logs.isEmpty else {
        promise(.success(true))
        return
      }

      guard let app = FilterExtensionXPC.shared.appReceiver else {
        promise(.success(false))
        return
      }

      let logData = logs.compactMap { try? JSON.data($0) }
      app.receiveBatchedHoneycombLogs(logData) { success in
        promise(.success(success))
      }
    }
    .eraseToAnyPublisher()
  }

  static func log(_ logMsg: Log.Message) {
    guard let json = try? JSON.data(logMsg) else {
      OsLogger().error("Error getting json data from LogMsg(\(logMsg.message)")
      return
    }
    FilterExtensionXPC.shared.appReceiver?.receiveLog(json)
  }

  static func recentFilterDecisions(_ decisions: [FilterDecision]) {
    let data = decisions.compactMap { try? JSON.data($0) }
    FilterExtensionXPC.shared.appReceiver?.receiveRecentFilterDecisions(data)
  }
}

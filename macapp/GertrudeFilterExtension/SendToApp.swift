import Combine
import Foundation
import Shared
import os.log
import SharedCore

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

      app.receiveBatchedHoneycombLogs(logs.compactMap(\.jsonData)) { success in
        promise(.success(success))
      }
    }
    .eraseToAnyPublisher()
  }

  static func log(_ logMsg: Log.Message) {
    guard let json = logMsg.jsonData else {
      OsLogger().error("Error getting json data from LogMsg(\(logMsg.message)")
      return
    }
    FilterExtensionXPC.shared.appReceiver?.receiveLog(json)
  }

  static func recentFilterDecisions(_ decisions: [FilterDecision]) {
    let data = decisions.compactMap(\.jsonData)
    FilterExtensionXPC.shared.appReceiver?.receiveRecentFilterDecisions(data)
  }
}

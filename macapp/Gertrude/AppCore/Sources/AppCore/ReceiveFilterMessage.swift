import Combine
import Foundation
import Gertie
import SharedCore
import XCore

@objc class ReceiveFilterMessage: NSObject, ReceiveFilterMessageInterface {
  private var cancellables: Set<AnyCancellable> = []

  func receiveBatchedHoneycombLogs(
    _ data: [Data],
    completionHandler: @escaping (Bool) -> Void
  ) {
    guard !data.isEmpty else {
      completionHandler(true)
      return
    }

    let messages = data.compactMap { try? JSON.decode($0, as: Log.Message.self) }
    if messages.count != data.count {
      log(.decodeCountError(Log.Message.self, expected: data.count, actual: messages.count))
    }

    guard !messages.isEmpty else {
      completionHandler(false)
      return
    }

    Current.honeycomb.send(messages.map(Honeycomb.Event.init))
      .sink { success in completionHandler(success) }
      .store(in: &cancellables)
  }

  func receiveLog(_ logData: Data) {
    guard let logMsg = try? JSON.decode(logData, as: Log.Message.self) else {
      log(.decodeError(Log.Message.self, String(data: logData, encoding: .utf8)))
      return
    }
    DispatchQueue.main.async { App.shared.store.send(.receivedNewAppLog(logMsg)) }
  }

  func receiveRecentFilterDecisions(_ decisionsData: [Data]) {
    let decisions = decisionsData.compactMap { try? JSON.decode($0, as: FilterDecision.self) }
    Current.api.uploadFilterDecisions(decisions)
  }
}

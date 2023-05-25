import Combine
import CombineSchedulers
import Foundation
import Gertie
import SharedCore

public extension Honeycomb {
  final class FilterLogger: LoggerProtocol {
    let send: ([Log.Message]) -> AnyPublisher<Bool, Never>
    let batchSize: Int
    let batchInterval: DispatchQueue.SchedulerTimeType.Stride
    let scheduler: AnySchedulerOf<DispatchQueue>
    let debugSessionId: UUID?

    var logs: [Log.Message] = []
    var cancellables: [AnyCancellable] = []

    public init(
      debugSessionId: UUID? = nil,
      send: @escaping ([Log.Message]) -> AnyPublisher<Bool, Never>,
      batchSize: Int = isDev() ? 20 : 2000,
      batchInterval: DispatchQueue.SchedulerTimeType.Stride = isDev() ? 30 : 60 * 5,
      scheduler: AnySchedulerOf<DispatchQueue>
    ) {
      self.debugSessionId = debugSessionId
      self.send = send
      self.batchSize = batchSize
      self.batchInterval = batchInterval
      self.scheduler = scheduler

      scheduler.schedule(
        after: scheduler.now.advanced(by: batchInterval),
        interval: batchInterval
      ) { [weak self] in
        self?.sendLogs()
      }.store(in: &cancellables)
    }

    public func log(_ message: Log.Message) {
      // memory failsafe--if we haven't been able to unload the events
      // for too long, we'll just drop them, @TODO: maybe try bugsnag here?
      if logs.count > batchSize * 100 {
        logs = []
      }

      if let debugId = debugSessionId {
        logs.append(message.addingMeta(["debug.session_id": .string(debugId.lowercased)]))
      } else {
        logs.append(message)
      }

      if logs.count >= batchSize {
        sendLogs()
      }
    }

    private func sendLogs() {
      guard !logs.isEmpty else { return }
      let toSend = logs
      logs = []
      send(toSend)
        .sink { sendSuccess in
          guard !sendSuccess else { return }
          self.logs.append(contentsOf: toSend)
        }
        .store(in: &cancellables)
    }

    public func flush() {
      sendLogs()
    }
  }
}

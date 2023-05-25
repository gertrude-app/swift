import Combine
import CombineSchedulers
import Foundation
import Gertie
import SharedCore

extension Honeycomb {
  actor Events {
    private var data: [Event] = []

    var isEmpty: Bool {
      count == 0
    }

    var count: Int {
      data.count
    }

    func clear() {
      data = []
    }

    func append(_ events: [Event]) {
      data.append(contentsOf: events)
    }

    func append(_ event: Event) {
      data.append(event)
    }

    func removeAll() -> [Event] {
      let copy = data
      clear()
      return copy
    }
  }

  final class AppLogger: LoggerProtocol {
    let getIsConnected: () -> Bool
    let send: ([Event]) -> AnyPublisher<Bool, Never>
    let batchSize: Int
    let batchInterval: DispatchQueue.SchedulerTimeType.Stride
    let scheduler: AnySchedulerOf<DispatchQueue>
    let debugSessionId: UUID?
    var events = Events()
    var cancellables: [AnyCancellable] = []
    var sendingPaused = false

    private var isConnected: Bool { getIsConnected() }

    init(
      debugSessionId: UUID? = nil,
      batchSize: Int = isDev() ? 10 : 2000,
      batchInterval: DispatchQueue.SchedulerTimeType.Stride = isDev() ? 15 : 60 * 5,
      scheduler: AnySchedulerOf<DispatchQueue> = .main,
      getIsConnected: @escaping () -> Bool,
      send: @escaping ([Event]) -> AnyPublisher<Bool, Never>
    ) {
      self.debugSessionId = debugSessionId
      self.getIsConnected = getIsConnected
      self.send = send
      self.batchSize = batchSize
      self.batchInterval = batchInterval
      self.scheduler = scheduler

      scheduler.schedule(
        after: scheduler.now.advanced(by: batchInterval),
        interval: batchInterval
      ) { [weak self] in
        self?.sendEvents()
      }.store(in: &cancellables)
    }

    private func sendEvents() {
      Task {
        let isEmpty = await events.isEmpty
        guard isConnected, !sendingPaused, !isEmpty else { return }
        let toSend = await events.removeAll()
        send(toSend)
          .sink { sendSuccess in
            guard !sendSuccess else { return }
            Task { await self.events.append(toSend) }
            self.pauseSending()
            AppCore.log(.warn("honeycomb > batch send failure, pausing"))
          }
          .store(in: &cancellables)
        AppCore.log(.level(.debug, "honeycomb > batch sent", .primary("count=\(toSend.count)")))
      }
    }

    private func pauseSending() {
      sendingPaused = true
      scheduler.schedule(after: scheduler.now.advanced(by: batchInterval)) { [weak self] in
        self?.sendingPaused = false
        AppCore.log(.info("honeycomb > un-pause sending"))
      }
    }

    func log(_ logMsg: Log.Message) {
      Task {
        // memory failsafe--if we haven't been able to unload the events
        // for too long, we'll just drop them, @TODO: maybe try bugsnag here?
        let count = await events.count
        if count > batchSize * 100 {
          await events.clear()
        }

        if let id = debugSessionId {
          await events
            .append(Event(logMsg).addingMeta(["debug.session_id": .string(id.lowercased)]))
        } else {
          await events.append(Event(logMsg))
        }

        guard isConnected, count >= batchSize else { return }
        sendEvents()
      }
    }

    func flush() {
      sendingPaused = false
      sendEvents()
    }
  }
}


import Foundation
import Gertie
import SharedCore

extension AppState {
  struct Logging: Equatable {
    var debugExpiration: Date?
    var toConsole: Bool
    var toAppWindow: Bool

    var debugging: Bool {
      debugExpiration.map { $0 > Date() } ?? false
    }

    var filter: LoggingState {
      .init(
        console: toConsole || isTestMachine() ? .all : .none,
        appWindow: toAppWindow ? .all : .none,
        honeycomb: debugging ? .debug : .filterHoneycombDefault
      )
    }
  }
}

extension AppState.Logging {
  init() {
    self.init(
      debugExpiration: nil,
      toConsole: isTestMachine(),
      toAppWindow: false
    )
  }
}

typealias IdentifiedLog = Identified<UUID, Log.Message>

extension AppState {
  struct LoggingWindow: Equatable {
    var logs: [IdentifiedLog] = []
  }
}

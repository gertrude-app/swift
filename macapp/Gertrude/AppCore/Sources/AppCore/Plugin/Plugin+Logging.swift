import Foundation
import Gertie
import SharedCore
import SwiftUI

class LoggingPlugin: NSObject, WindowPlugin {
  var store: AppStore
  var windowOpen = false
  var window: NSWindow?
  var title = "Logs  |  Gertrude"

  var initialDims: (width: CGFloat, height: CGFloat) {
    (width: LogsWindow.MIN_WIDTH, height: LogsWindow.MIN_HEIGHT)
  }

  var contentView: NSView {
    NSHostingView(rootView: LogsWindow().environmentObject(store))
  }

  var state: AppState.Logging {
    store.state.logging
  }

  init(store: AppStore) {
    self.store = store
    super.init()

    Current.logger = AppLogger(store: store)

    // give time for XPC connection to be established
    // @TODO: would be better to have the state know about the XPC connection
    // than sprinkling these timeouts everywhere
    afterDelayOf(seconds: 2) { [weak self] in
      self?.sendFilterPersistentLogData()
    }
  }

  func sendFilterPersistentLogData() {
    tellFilter(.setPersistentConsoleConfig(state.filter.console))
    tellFilter(.setPersistentHoneycombConfig(state.filter.honeycomb))
  }

  func tellFilter(_ command: AppToFilterLoggingCommand) {
    ifFilterConnected {
      SendToFilter.loggingCommand(command)
    }
  }

  func respond(to event: AppEvent) {
    switch event {
    case .startDebugLogging(expiration: let expiration):
      let session = DebugSession(id: UUID(), expiration: expiration)
      Current.logger.startDebugSession(session)
      tellFilter(.startDebugSession(session))

    case .stopDebugLogging:
      Current.logger.endDebugSession()
      tellFilter(.endDebugSession)

    case .appWindowLoggingChanged:
      Current.logger.configureAppWindow()

    case .consoleLoggingChanged:
      Current.logger.configureConsole()
      tellFilter(.setPersistentConsoleConfig(state.filter.console))

    case .honeycombLoggingChanged:
      Current.logger.configureHoneycomb()
      tellFilter(.setPersistentHoneycombConfig(state.filter.honeycomb))

    case .logsWindowOpened:
      openWindow()
      tellFilter(.startAppWindowLogging)

    case .filterStatusChanged:
      sendFilterPersistentLogData()

    default:
      break
    }
  }

  func windowWillClose(_ notification: Notification) {
    windowOpen = false
    store.send(.closeAppLogsWindow)
    tellFilter(.stopAppWindowLogging)
  }
}

public func log(_ event: AppLogEvent, file: StaticString = #fileID, line: UInt = #line) {
  var message = event.logMessage
  message.meta["location"] = .string("\(file):\(line)")
  Current.logger.log(message)
}

public func debug(_ event: AppDebugEvent, file: StaticString = #fileID, line: UInt = #line) {
  var message = event.logMessage
  if message.level != .error {
    message.level = .debug
  }
  message.meta["location"] = .string("\(file):\(line)")
  Current.logger.log(message)
}

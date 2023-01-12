import FilterCore
import Foundation
import SharedCore

struct Env {
  var filterVersion: String
  var logger: GertieLogger
}

var Current = Env(
  filterVersion: Bundle.main.version,

  // real logger initialized in FilterDataProvider
  // to prevent recursive static reference crash from
  // logging while setting up real logger
  logger: GertieNullLogger()
)

// global loggers

public func log(_ event: FilterLogEvent, file: StaticString = #fileID, line: UInt = #line) {
  var message = event.logMessage
  message.meta["filter"] = true
  message.meta["location"] = .string("\(file):\(line)")
  message.meta["app.filter_version"] = .string(Current.filterVersion)
  Current.logger.log(message)
}

public func debug(_ event: FilterDebugEvent, file: StaticString = #fileID, line: UInt = #line) {
  var message = event.logMessage
  if message.level != .error {
    message.level = .debug
  }
  message.meta["filter"] = true
  message.meta["location"] = .string("\(file):\(line)")
  message.meta["app.filter_version"] = .string(Current.filterVersion)
  Current.logger.log(message)
}

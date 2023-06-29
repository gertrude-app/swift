import AppKit
import Dependencies
import Foundation
import MacAppRoute

struct MonitoringClient: Sendable {
  var keystrokeRecordingPermissionGranted: @Sendable () async -> Bool
  var screenRecordingPermissionGranted: @Sendable () async -> Bool
  var startLoggingKeystrokes: @Sendable () async -> Void
  var stopLoggingKeystrokes: @Sendable () async -> Void
  var takePendingKeystrokes: @Sendable () async -> CreateKeystrokeLines.Input?
  var takeScreenshot: @Sendable (Int) async throws -> (data: Data, width: Int, height: Int)?
}

extension MonitoringClient: DependencyKey {
  static let liveValue = Self(
    keystrokeRecordingPermissionGranted: {
      #if DEBUG
        // prevent warning while developing
        return true
      #else
        // no way to make this not a concurrency warning (that i can figure out)
        // as it's a global mutable CFString variable, but this thread is interesting:
        // https://developer.apple.com/forums/thread/707680 - maybe i could use that
        // api, and possibly restore sandboxing
        let options: NSDictionary =
          [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options)
      #endif
    },
    screenRecordingPermissionGranted: { CGPreflightScreenCaptureAccess() },
    startLoggingKeystrokes: startKeylogging,
    stopLoggingKeystrokes: stopKeylogging,
    takePendingKeystrokes: takeKeystrokes,
    takeScreenshot: takeScreenshot(width:)
  )
}

extension MonitoringClient: TestDependencyKey {
  static let testValue = Self(
    keystrokeRecordingPermissionGranted: { true },
    screenRecordingPermissionGranted: { true },
    startLoggingKeystrokes: {},
    stopLoggingKeystrokes: {},
    takePendingKeystrokes: { [] },
    takeScreenshot: { _ in (data: .init(), width: 900, height: 600) }
  )
}

extension DependencyValues {
  var monitoring: MonitoringClient {
    get { self[MonitoringClient.self] }
    set { self[MonitoringClient.self] = newValue }
  }
}

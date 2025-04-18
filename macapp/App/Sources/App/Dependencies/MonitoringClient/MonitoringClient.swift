import AppKit
import Dependencies
import Foundation
import MacAppRoute

struct MonitoringClient: Sendable {
  var commitPendingKeystrokes: @Sendable (Bool) async -> Void
  var keystrokeRecordingPermissionGranted: @Sendable () async -> Bool
  var restorePendingKeystrokes: @Sendable (CreateKeystrokeLines.Input) async -> Void
  var screenRecordingPermissionGranted: @Sendable () async -> Bool
  var startLoggingKeystrokes: @Sendable () async -> Void
  var stopLoggingKeystrokes: @Sendable () async -> Void
  var takePendingKeystrokes: @Sendable () async -> CreateKeystrokeLines.Input?
  var takePendingScreenshots: @Sendable () async -> [ScreenshotData]
  var takeScreenshot: @Sendable (Int) async throws -> Void
}

extension MonitoringClient: DependencyKey {
  static let liveValue = Self(
    commitPendingKeystrokes: commitKestrokes(filterSuspended:),
    keystrokeRecordingPermissionGranted: {
      #if DEBUG
        // prevent warning while developing
        return true
      #else
        // no way to make this NOT a concurrency warning (that i can figure out)
        // as it's a global mutable CFString variable, but this thread is interesting:
        // https://developer.apple.com/forums/thread/707680 - maybe i could use that
        // api, and possibly restore sandboxing
        let options: NSDictionary =
          [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options)
      #endif
    },
    restorePendingKeystrokes: restoreKeystrokes(_:),
    screenRecordingPermissionGranted: isScreenRecordingPermissionGranted,
    startLoggingKeystrokes: startKeylogging,
    stopLoggingKeystrokes: stopKeylogging,
    takePendingKeystrokes: takeKeystrokes,
    takePendingScreenshots: { screenshotBuffer.removeAll() },
    takeScreenshot: takeScreenshot(width:)
  )
}

extension MonitoringClient: TestDependencyKey {
  static let testValue = Self(
    commitPendingKeystrokes: unimplemented("MonitoringClient.commitPendingKeystrokes"),
    keystrokeRecordingPermissionGranted: unimplemented(
      "MonitoringClient.keystrokeRecordingPermissionGranted",
      placeholder: true
    ),
    restorePendingKeystrokes: unimplemented("MonitoringClient.restorePendingKeystrokes"),
    screenRecordingPermissionGranted: unimplemented(
      "MonitoringClient.screenRecordingPermissionGranted",
      placeholder: true
    ),
    startLoggingKeystrokes: unimplemented("MonitoringClient.startLoggingKeystrokes"),
    stopLoggingKeystrokes: unimplemented("MonitoringClient.stopLoggingKeystrokes"),
    takePendingKeystrokes: unimplemented(
      "MonitoringClient.takePendingKeystrokes",
      placeholder: nil
    ),
    takePendingScreenshots: unimplemented(
      "MonitoringClient.takePendingScreenshots",
      placeholder: []
    ),
    takeScreenshot: unimplemented("MonitoringClient.takeScreenshot")
  )
  static let mock = Self(
    commitPendingKeystrokes: { _ in },
    keystrokeRecordingPermissionGranted: { true },
    restorePendingKeystrokes: { _ in },
    screenRecordingPermissionGranted: { true },
    startLoggingKeystrokes: {},
    stopLoggingKeystrokes: {},
    takePendingKeystrokes: { [] },
    takePendingScreenshots: { [] },
    takeScreenshot: { _ in }
  )
}

extension DependencyValues {
  var monitoring: MonitoringClient {
    get { self[MonitoringClient.self] }
    set { self[MonitoringClient.self] = newValue }
  }
}

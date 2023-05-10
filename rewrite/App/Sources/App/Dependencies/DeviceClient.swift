import AppKit
import Dependencies
import Foundation

struct DeviceClient: Sendable {
  var currentMacOsUserType: @Sendable () async throws -> MacOsUserType
  var fullUsername: @Sendable () -> String
  var hostname: @Sendable () -> String?
  var keystrokeRecordingPermissionGranted: @Sendable () async -> Bool
  var modelIdentifier: @Sendable () -> String?
  var notificationsSetting: @Sendable () async -> NotificationsSetting
  var numericUserId: @Sendable () -> uid_t
  var openSystemPrefs: @Sendable (SystemPrefsLocation) async -> Void
  var openWebUrl: @Sendable (URL) async -> Void
  var quitBrowsers: @Sendable () async -> Void
  var screenRecordingPermissionGranted: @Sendable () async -> Bool
  var showNotification: @Sendable (String, String) async -> Void
  var serialNumber: @Sendable () -> String?
  var username: @Sendable () -> String
}

extension DeviceClient: DependencyKey {
  static let liveValue = Self(
    currentMacOsUserType: getCurrentMacOsUserType,
    fullUsername: { NSFullUserName() },
    hostname: { Host.current().localizedName },
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
    modelIdentifier: { platform("model", format: .data)?.filter { $0 != .init("\0") } },
    notificationsSetting: getNotificationsSetting,
    numericUserId: { getuid() },
    openSystemPrefs: openSystemPrefs(at:),
    openWebUrl: { NSWorkspace.shared.open($0) },
    quitBrowsers: quitAllBrowsers,
    screenRecordingPermissionGranted: { CGPreflightScreenCaptureAccess() },
    showNotification: showNotification(title:body:),
    serialNumber: { platform(kIOPlatformSerialNumberKey, format: .string) },
    username: { NSUserName() }
  )
}

extension DeviceClient: TestDependencyKey {
  static let testValue = Self(
    currentMacOsUserType: { .standard },
    fullUsername: { "test-full-username" },
    hostname: { "test-hostname" },
    keystrokeRecordingPermissionGranted: { true },
    modelIdentifier: { "test-model-identifier" },
    notificationsSetting: { .alert },
    numericUserId: { 502 },
    openSystemPrefs: { _ in },
    openWebUrl: { _ in },
    quitBrowsers: {},
    screenRecordingPermissionGranted: { true },
    showNotification: { _, _ in },
    serialNumber: { "test-serial-number" },
    username: { "test-username" }
  )
}

extension DependencyValues {
  var device: DeviceClient {
    get { self[DeviceClient.self] }
    set { self[DeviceClient.self] = newValue }
  }
}

// implementation

private enum Format { case data, string }

private func platform(_ key: String, format: Format) -> String? {
  let service = IOServiceGetMatchingService(
    kIOMasterPortDefault,
    IOServiceMatching("IOPlatformExpertDevice")
  )

  defer { IOObjectRelease(service) }

  let property = IORegistryEntryCreateCFProperty(
    service,
    key as CFString,
    kCFAllocatorDefault,
    /* option bits */ 0
  )

  switch format {
  case .data:
    return (property?.takeRetainedValue() as? Data)
      .flatMap { String(data: $0, encoding: .utf8) }
  case .string:
    return property?.takeRetainedValue() as? String
  }
}

// https://di-api.reincubate.com/v1/apple-serials/C07D92QVPJJ9/

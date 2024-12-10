import AppKit
import Dependencies
import Foundation
import Gertie
import SystemConfiguration

struct DeviceClient: Sendable {
  var currentMacOsUserType: @Sendable () async throws -> MacOSUserType
  var currentUserId: @Sendable () -> uid_t
  // @see https://developer.apple.com/forums/thread/707522
  var currentUserHasScreen: @Sendable () -> Bool
  var fullUsername: @Sendable () -> String
  var listMacOSUsers: @Sendable () async throws -> [MacOSUser]
  var modelIdentifier: @Sendable () -> String?
  var notificationsSetting: @Sendable () async -> NotificationsSetting
  var numericUserId: @Sendable () -> uid_t
  var openSystemPrefs: @Sendable (SystemPrefsLocation) async -> Void
  var openWebUrl: @Sendable (URL) async -> Void
  var osVersion: @Sendable () -> MacOSVersion
  var quitBrowsers: @Sendable ([BrowserMatch]) async -> Void
  var requestNotificationAuthorization: @Sendable () async -> Void
  var screensaverRunning: @Sendable () -> Bool
  var showNotification: @Sendable (String, String) async -> Void
  var serialNumber: @Sendable () -> String?
  var terminateBlockedApps: @Sendable ([BlockedApp]) async -> Void
  var terminateApp: @Sendable (NSRunningApplication) async -> Void
  var username: @Sendable () -> String
  var boottime: @Sendable () -> Date?
}

extension DeviceClient: DependencyKey {
  static let liveValue = Self(
    currentMacOsUserType: getCurrentMacOSUserType,
    currentUserId: { getuid() },
    currentUserHasScreen: {
      var uid: uid_t = 0
      SCDynamicStoreCopyConsoleUser(nil, &uid, nil)
      // in my testing, sometimes the console user got stuck at 0 as the
      // `loginwindow` user, so consider the loginwindow the current user as well
      return uid == getuid() || uid == 0
    },
    fullUsername: { NSFullUserName() },
    listMacOSUsers: getAllMacOSUsers,
    modelIdentifier: { platform("model", format: .data)?.filter { $0 != .init("\0") } },
    notificationsSetting: getNotificationsSetting,
    numericUserId: { getuid() },
    openSystemPrefs: openSystemPrefs(at:),
    openWebUrl: { NSWorkspace.shared.open($0) },
    osVersion: { macOSVersion() },
    quitBrowsers: quitAllBrowsers,
    requestNotificationAuthorization: requestNotificationAuth,
    screensaverRunning: {
      let currentApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
      return currentApp == "com.apple.ScreenSaver.Engine" || currentApp == "com.apple.loginwindow"
    },
    showNotification: showNotification(title:body:),
    serialNumber: { platform(kIOPlatformSerialNumberKey, format: .string) },
    terminateBlockedApps: terminateAllBlockedApps,
    terminateApp: terminateRunningApp(_:),
    username: { NSUserName() },
    boottime: {
      // https://forums.developer.apple.com/forums/thread/101874?answerId=309633022#309633022
      var tv = timeval()
      var tvSize = MemoryLayout<timeval>.size
      let err = sysctlbyname("kern.boottime", &tv, &tvSize, nil, 0)
      guard err == 0, tvSize == MemoryLayout<timeval>.size else {
        return nil
      }
      return Date(timeIntervalSince1970: Double(tv.tv_sec) + (Double(tv.tv_usec) / 1_000_000.0))
    }
  )
}

extension DeviceClient: TestDependencyKey {
  static let testValue = Self(
    currentMacOsUserType: unimplemented("DeviceClient.currentMacOsUserType"),
    currentUserId: unimplemented("DeviceClient.currentUserId", placeholder: 502),
    currentUserHasScreen: unimplemented("DeviceClient.currentUserHasScreen", placeholder: true),
    fullUsername: unimplemented("DeviceClient.fullUsername", placeholder: ""),
    listMacOSUsers: unimplemented("DeviceClient.listMacOSUsers"),
    modelIdentifier: unimplemented("DeviceClient.modelIdentifier", placeholder: nil),
    notificationsSetting: unimplemented("DeviceClient.notificationsSetting", placeholder: .none),
    numericUserId: unimplemented("DeviceClient.numericUserId", placeholder: 502),
    openSystemPrefs: unimplemented("DeviceClient.openSystemPrefs"),
    openWebUrl: unimplemented("DeviceClient.openWebUrl"),
    osVersion: unimplemented(
      "DeviceClient.osVersion",
      placeholder: .init(major: 15, minor: 0, patch: 0)
    ),
    quitBrowsers: unimplemented("DeviceClient.quitBrowsers"),
    requestNotificationAuthorization: unimplemented(
      "DeviceClient.requestNotificationAuthorization"
    ),
    screensaverRunning: unimplemented("DeviceClient.screensaverRunning", placeholder: false),
    showNotification: unimplemented("DeviceClient.showNotification"),
    serialNumber: unimplemented("DeviceClient.serialNumber", placeholder: ""),
    terminateBlockedApps: unimplemented("DeviceClient.terminateBlockedApps"),
    terminateApp: unimplemented("DeviceClient.terminateApp"),
    username: unimplemented("DeviceClient.username", placeholder: ""),
    boottime: unimplemented("DeviceClient.boottime", placeholder: nil)
  )

  static let mock = Self(
    currentMacOsUserType: { .standard },
    currentUserId: { 502 },
    currentUserHasScreen: { true },
    fullUsername: { "test-full-username" },
    listMacOSUsers: { [
      .init(id: 501, name: "Dad", type: .admin),
      .init(id: 502, name: "liljimmy", type: .standard),
    ] },
    modelIdentifier: { "test-model-identifier" },
    notificationsSetting: { .alert },
    numericUserId: { 502 },
    openSystemPrefs: { _ in },
    openWebUrl: { _ in },
    osVersion: { .init(major: 14, minor: 0, patch: 0) },
    quitBrowsers: { _ in },
    requestNotificationAuthorization: {},
    screensaverRunning: { false },
    showNotification: { _, _ in },
    serialNumber: { "test-serial-number" },
    terminateBlockedApps: { _ in },
    terminateApp: { _ in },
    username: { "test-username" },
    boottime: { nil }
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

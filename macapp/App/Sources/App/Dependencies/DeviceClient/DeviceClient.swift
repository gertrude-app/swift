import AppKit
import Dependencies
import Foundation

struct DeviceClient: Sendable {
  var currentMacOsUserType: @Sendable () async throws -> MacOSUserType
  var currentUserId: @Sendable () -> uid_t
  var fullUsername: @Sendable () -> String
  var listMacOSUsers: @Sendable () async throws -> [MacOSUser]
  var modelIdentifier: @Sendable () -> String?
  var notificationsSetting: @Sendable () async -> NotificationsSetting
  var numericUserId: @Sendable () -> uid_t
  var openSystemPrefs: @Sendable (SystemPrefsLocation) async -> Void
  var openWebUrl: @Sendable (URL) async -> Void
  var quitBrowsers: @Sendable () async -> Void
  var requestNotificationAuthorization: @Sendable () async -> Void
  var showNotification: @Sendable (String, String) async -> Void
  var serialNumber: @Sendable () -> String?
  var username: @Sendable () -> String
}

extension DeviceClient: DependencyKey {
  static let liveValue = Self(
    currentMacOsUserType: getCurrentMacOSUserType,
    currentUserId: { getuid() },
    fullUsername: { NSFullUserName() },
    listMacOSUsers: getAllMacOSUsers,
    modelIdentifier: { platform("model", format: .data)?.filter { $0 != .init("\0") } },
    notificationsSetting: getNotificationsSetting,
    numericUserId: { getuid() },
    openSystemPrefs: openSystemPrefs(at:),
    openWebUrl: { NSWorkspace.shared.open($0) },
    quitBrowsers: quitAllBrowsers,
    requestNotificationAuthorization: requestNotificationAuth,
    showNotification: showNotification(title:body:),
    serialNumber: { platform(kIOPlatformSerialNumberKey, format: .string) },
    username: { NSUserName() }
  )
}

extension DeviceClient: TestDependencyKey {
  static let testValue = Self(
    currentMacOsUserType: { .standard },
    currentUserId: { 502 },
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
    quitBrowsers: {},
    requestNotificationAuthorization: {},
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

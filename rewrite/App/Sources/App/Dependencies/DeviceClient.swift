import AppKit
import Dependencies
import Foundation
import UserNotifications

struct DeviceClient: Sendable {
  var fullUsername: @Sendable () -> String
  var hostname: @Sendable () -> String?
  var modelIdentifier: @Sendable () -> String?
  var numericUserId: @Sendable () -> uid_t
  var openWebUrl: @Sendable (URL) async -> Void
  var showNotification: @Sendable (String, String) async -> Void
  var serialNumber: @Sendable () -> String?
  var username: @Sendable () -> String
}

extension DeviceClient: DependencyKey {
  static let liveValue = Self(
    fullUsername: { NSFullUserName() },
    hostname: { Host.current().localizedName },
    modelIdentifier: { platform("model", format: .data)?.filter { $0 != .init("\0") } },
    numericUserId: { getuid() },
    openWebUrl: { NSWorkspace.shared.open($0) },
    showNotification: { title, body in
      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body
      UNUserNotificationCenter.current().add(UNNotificationRequest(
        identifier: UUID().uuidString,
        content: content,
        trigger: nil
      ))
    },
    serialNumber: { platform(kIOPlatformSerialNumberKey, format: .string) },
    username: { NSUserName() }
  )
}

extension DeviceClient: TestDependencyKey {
  static let testValue = Self(
    fullUsername: { "test-full-username" },
    hostname: { "test-hostname" },
    modelIdentifier: { "test-model-identifier" },
    numericUserId: { 502 },
    openWebUrl: { _ in },
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
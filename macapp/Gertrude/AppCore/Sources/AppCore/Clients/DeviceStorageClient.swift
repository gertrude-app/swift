import Foundation
import SharedCore

struct DeviceStorageClient {
  enum Key: String, CaseIterable {
    case gertrudeUserId
    case gertrudeDeviceId
    case filterRestartFailsafe
    case installedAppVersion
    case userToken = "guardianToken"
    case keyloggingEnabled
    case screenshotsEnabled
    case screenshotFrequency
    case screenshotSize
    case graphQLEndpointOverride
    case pairQLEndpointOverride
    case websocketEndpointOverride
    case appcastEndpointOverride
    case releaseChannel

    var namespaced: String {
      "device_storage.\(rawValue)"
    }
  }

  var get: (Key) -> String?
  var set: (Key, String) -> Void
  var delete: (Key) -> Void
  var purgeAll: () -> Void
}

extension DeviceStorageClient {
  func getInt(_ key: Key) -> Int? {
    get(key).flatMap { Int($0) }
  }

  func setInt(_ key: Key, _ value: Int) {
    set(key, String(value))
  }

  func getUUID(_ key: Key) -> UUID? {
    get(key).flatMap { UUID(uuidString: $0) }
  }

  func setUUID(_ key: Key, _ value: UUID) {
    set(key, value.uuidString)
  }

  func getBool(_ key: Key) -> Bool? {
    get(key).flatMap { $0 == "true" ? true : false }
  }

  func setBool(_ key: Key, _ value: Bool) {
    set(key, value ? "true" : "false")
  }

  func setDate(_ key: Key, _ value: Date) {
    set(key, value.isoString)
  }

  func getDate(_ key: Key) -> Date? {
    get(key).flatMap { isoDateFormatter.date(from: $0) }
  }

  func getURL(_ key: Key) -> URL? {
    get(key).flatMap { URL(string: $0) }
  }

  func setURL(_ key: Key, _ value: URL) {
    set(key, value.absoluteString)
  }
}

extension DeviceStorageClient {
  static var live: DeviceStorageClient {
    func load(_ key: Key) -> String? {
      UserDefaults.standard.string(forKey: key.namespaced)
    }

    func save(_ key: Key, _ value: String) {
      UserDefaults.standard.set(value, forKey: key.namespaced)
    }

    func _delete(_ key: Key) {
      UserDefaults.standard.removeObject(forKey: key.namespaced)
    }

    return DeviceStorageClient(
      get: { key in
        load(key)
      },
      set: { key, value in
        save(key, value)
      },
      delete: { key in
        _delete(key)
      },
      purgeAll: {
        Key.allCases.forEach(_delete)
      }
    )
  }
}

extension DeviceStorageClient {
  static let noop = DeviceStorageClient(
    get: { _ in nil },
    set: { _, _ in },
    delete: { _ in },
    purgeAll: {}
  )
}

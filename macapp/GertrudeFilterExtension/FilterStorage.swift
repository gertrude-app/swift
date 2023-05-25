import FilterCore
import Foundation
import Gertie
import SharedCore
import XCore

enum FilterStorage {
  public typealias Key = FilterStorageKey
  private static var storage: UserDefaults { UserDefaults.standard }

  public enum LogSink: Equatable {
    case console
    case honeycomb
  }

  static func loadLoggingConfig(for sink: LogSink) -> Log.Config? {
    let key = sink == .console ? Key.consoleLoggingConfig : Key.honeycombLoggingConfig
    guard let json = storage.string(forKey: key) else {
      log(.filterStorage(.missingData(Log.Config.self, key)))
      return nil
    }

    guard let config = try? JSON.decode(json, as: Log.Config.self) else {
      log(.decodeError(Log.Config.self, json))
      return nil
    }

    log(.filterStorage(.load(Log.Config.self, key, json)))
    return config
  }

  static func saveLoggingConfig(_ config: Log.Config, for sink: LogSink) {
    let key = sink == .console ? Key.consoleLoggingConfig : Key.honeycombLoggingConfig
    guard let json = try? JSON.encode(config) else {
      log(.encodeError(Log.Config.self))
      return
    }
    storage.set(json, forKey: key)
    log(.filterStorage(.save(LoggingState.self, key, json)))
  }

  static func saveIdManifest(_ idManifest: AppIdManifest) {
    guard let json = try? JSON.encode(idManifest) else {
      log(.encodeError(AppIdManifest.self))
      return
    }
    storage.set(json, forKey: .idManifest)
    log(.filterStorage(.save(AppIdManifest.self, .idManifest, json)))
  }

  static func loadIdManifest() {
    guard let json = storage.string(forKey: .idManifest) else {
      log(.filterStorage(.missingData(AppIdManifest.self, .idManifest)))
      return
    }

    guard let manifest = try? JSON.decode(json, as: AppIdManifest.self) else {
      log(.decodeError(AppIdManifest.self, json))
      return
    }

    FilterDataProvider.instance?.decisionMaker.appDescriptorFactory = AppDescriptorFactory(
      appIdManifest: manifest,
      rootAppQuery: RootAppDataQuery()
    )

    log(.filterStorage(.load(AppIdManifest.self, .idManifest, json)))
  }

  static func saveKeys(_ keys: [FilterKey], forUserWithId userId: uid_t) {
    guard keys.count > 0 else {
      log(.filterStorage(.emptyKeys(userId)))
      return
    }

    let strings = keys.compactMap { try? JSON.encode($0) }
    guard strings.count == keys.count else {
      log(.encodeCountError(FilterKey.self, expected: keys.count, actual: strings.count))
      return
    }

    storage.set(strings, forKey: .userKeys(userId))
    log(.filterStorage(.saveUserKeys(userId, keys.count)))
  }

  static func loadKeys(forUserWithId userId: uid_t) {
    if let keys = getKeys(forUserWithId: userId) {
      FilterDataProvider.instance?.decisionMaker.userKeys[userId] = keys
      log(.filterStorage(.loadUserKeys(userId, keys.count)))
    }
  }

  static func getKeys(forUserWithId userId: uid_t) -> [FilterKey]? {
    guard let keysJson = storage.stringArray(forKey: Key.userKeys(userId).string) else {
      log(.filterStorage(.missingUserData(userId, [FilterKey].self, .userKeys(userId))))
      return nil
    }

    guard keysJson.count > 0 else {
      log(.filterStorage(.emptyKeys(userId)))
      return nil
    }

    let keys = keysJson.compactMap { try? JSON.decode($0, as: FilterKey.self) }
    guard keys.count == keysJson.count else {
      log(.decodeCountError(FilterKey.self, expected: keysJson.count, actual: keys.count))
      return nil
    }

    return keys
  }

  static func getUsersWithKeys() -> Set<uid_t> {
    guard let csv = storage.string(forKey: .usersWithKeys) else {
      log(.filterStorage(.missingData(Set<uid_t>.self, .usersWithKeys)))
      return Set<uid_t>()
    }
    log(.filterStorage(.load(Set<uid_t>.self, .usersWithKeys, csv)))
    return csv.parseCommaSeparatedUserIds()
  }

  static func addUserWithKeys(_ userId: uid_t) {
    var ids = getUsersWithKeys()
    ids.insert(userId)
    let csv = String(fromUserIds: ids)
    storage.set(csv, forKey: Key.usersWithKeys.string)
    log(.filterStorage(.addUserWithKeys(userId, csv)))
  }

  static func getExemptedUserIds() -> Set<uid_t> {
    guard let csv = storage.string(forKey: .exemptUsers) else {
      log(.filterStorage(.missingData(Set<uid_t>.self, .exemptUsers)))
      return Set<uid_t>()
    }
    log(.filterStorage(.load(Set<uid_t>.self, .exemptUsers, csv)))
    return csv.parseCommaSeparatedUserIds()
  }

  static func addExemptedUserId(_ userId: uid_t) {
    var ids = getExemptedUserIds()
    ids.insert(userId)
    storage.set(String(fromUserIds: ids), forKey: Key.exemptUsers.string)
    log(.filterStorage(.addExemptUser(userId)))
  }

  static func removeExemptedUsers() {
    storage.set("", forKey: .exemptUsers)
    log(.filterStorage(.removeExemptUsers))
  }

  static func purgeAll() {
    Key.purgeKeys.forEach { storage.removeObject(forKey: $0) }
  }
}

extension UserDefaults {
  func set(_ value: Any?, forKey key: FilterStorage.Key) {
    set(value, forKey: key.string)
  }

  func string(forKey key: FilterStorage.Key) -> String? {
    string(forKey: key.string)
  }
}

import FilterCore
import Foundation
import Shared
import SharedCore
import XCore

@objc class ReceiveAppMessage: NSObject, ReceiveAppMessageInterface {
  func receiveSuspension(_ data: Data, for userId: uid_t) {
    guard let suspension = try? JSON.decode(data, as: FilterSuspension.self) else {
      log(.decodeError(FilterSuspension.self, String(data: data, encoding: .utf8)))
      return
    }
    FilterDataProvider.instance?.decisionMaker.suspensions.set(suspension, userId: userId)
    log(.receiveAppMessage(.setFilterSuspension(suspension, userId)))
  }

  func cancelSuspension(for userId: uid_t) {
    FilterDataProvider.instance?.decisionMaker.suspensions.revoke(userId: userId)
    log(.receiveAppMessage(.cancelSuspension(userId)))
  }

  func register(_ completionHandler: @escaping (Bool) -> Void) {
    log(.receiveAppMessage(.register))
    completionHandler(true)
  }

  var currentFilterLogger: FilterLogger? {
    Current.logger as? FilterLogger
  }

  func receiveLoggingCommand(_ data: Data) {
    guard let command = try? JSON.decode(data, as: AppToFilterLoggingCommand.self) else {
      log(.decodeError(AppToFilterLoggingCommand.self, String(data: data, encoding: .utf8)))
      return
    }

    log(.receiveAppMessage(.loggingCommand(command)))

    switch command {
    case .startAppWindowLogging:
      Current.logger.appWindow = ExpiringLogger(
        expiration: Date().advanced(by: 60 * 10),
        wrapped: FnLogger(send: SendToApp.log(_:)),
        onExpiration: {
          Current.logger.appWindow = NullLogger()
        }
      )
    case .stopAppWindowLogging:
      Current.logger.appWindow = NullLogger()
    case .startDebugSession(let session):
      Current.logger.startDebugSession(session)
    case .endDebugSession:
      Current.logger.configureHoneycomb()
    case .setPersistentConsoleConfig(let config):
      FilterStorage.saveLoggingConfig(config, for: .console)
      Current.logger.configureConsole()
    case .setPersistentHoneycombConfig(let config):
      FilterStorage.saveLoggingConfig(config, for: .honeycomb)
      Current.logger.configureHoneycomb()
    }
  }

  func transmitCurrentExemptUsers(_ handler: @escaping (Set<uid_t>) -> Void) {
    handler(FilterStorage.getExemptedUserIds())
  }

  func receiveExemptUsers(_ csv: String) {
    let ids = csv.parseCommaSeparatedUserIds()
    guard !ids.isEmpty else {
      log(.receiveAppMessage(.unexpectedEmptyExemptUserList(csv)))
      return
    }

    ids.forEach { FilterStorage.addExemptedUserId($0) }
    FilterDataProvider.instance?.loadExemptedUserList()
    log(.receiveAppMessage(.exemptUsers(ids)))
  }

  func removeAllExemptUsers() {
    log(.receiveAppMessage(.clearExemptUsers))
    FilterStorage.removeExemptedUsers()
    // force unwrap so that I crash the filter if I can't get an instance to clear exemptions
    // i'd rather force a crash and immediate relaunch of the filter than have this fail
    FilterDataProvider.instance!.loadExemptedUserList()
  }

  func receiveRefreshedRulesData(
    userId: uid_t,
    keys keysData: [Data],
    idManifest manifestData: Data,
    completionHandler: @escaping (Bool) -> Void
  ) {
    let keys = keysData.compactMap { try? JSON.decode($0, as: FilterKey.self) }
    if keys.count != keysData.count {
      log(.decodeCountError(FilterKey.self, expected: keysData.count, actual: keys.count))
      DispatchQueue.main.async { completionHandler(false) }
      return
    }

    FilterDataProvider.instance?.decisionMaker.userKeys[userId] = keys
    FilterStorage.saveKeys(keys, forUserWithId: userId)
    FilterStorage.addUserWithKeys(userId)
    log(.receiveAppMessage(.refreshRulesKeys(userId, keys.count)))
    debug(.receiveAppMessage(.refreshRulesKeys(userId, keys)))

    if let manifest = try? JSON.decode(manifestData, as: AppIdManifest.self) {
      log(.receiveAppMessage(.refreshRulesAppIdManifest(manifest)))
      debug(.receiveAppMessage(.refreshRulesAppIdManifest(manifest)))

      FilterDataProvider.instance?.decisionMaker.appDescriptorFactory = AppDescriptorFactory(
        appIdManifest: manifest,
        rootAppQuery: RootAppDataQuery()
      )

      FilterStorage.saveIdManifest(manifest)
      DispatchQueue.main.async { completionHandler(true) }
    } else {
      DispatchQueue.main.async { completionHandler(false) }
      log(.decodeError(AppIdManifest.self, String(data: manifestData, encoding: .utf8)))
    }
  }

  func transmitRecentFilterDecisions(_ handler: @escaping ([Data]) -> Void) {
    let data = FilterDataProvider.decisions.flushRecentFirst().compactMap(\.jsonData)
    if data.count > 0 {
      handler(data)
    }
  }

  func receiveConfirmCommunication(int: Int, handler: @escaping (Int) -> Void) {
    log(.receiveAppMessage(.confirmCommunication(int)))
    DispatchQueue.main.async { handler(int) }
  }

  func transmitCurrentVersion(_ handler: @escaping (String) -> Void) {
    log(.receiveAppMessage(.transmitCurrentVersion(Current.filterVersion)))
    DispatchQueue.main.async { handler(Current.filterVersion) }
  }

  func transmitNumKeysLoaded(for userId: uid_t, handler: @escaping (Int) -> Void) {
    let keys = FilterStorage.getKeys(forUserWithId: userId)
    log(.receiveAppMessage(.transmitNumKeysLoaded(userId, keys?.count ?? -1)))
    DispatchQueue.main.async {
      handler(keys?.count ?? -1)
    }
  }

  func purgeAllDeviceStorage() {
    log(.receiveAppMessage(.purgeAllDeviceStorage))
    FilterStorage.purgeAll()
  }
}

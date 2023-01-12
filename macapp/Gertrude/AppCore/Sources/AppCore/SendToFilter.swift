import Foundation
import Shared
import SharedCore

struct SendToFilter {
  static var filter: ReceiveAppMessageInterface? {
    FilterController.shared.filterReceiver
  }

  static func refreshedRulesData(
    keys: [Data],
    idManifest: Data,
    completionHandler: @escaping (Bool) -> Void
  ) {
    DispatchQueue.global(qos: .userInitiated).async {
      filter?.receiveRefreshedRulesData(
        userId: getuid(),
        keys: keys,
        idManifest: idManifest,
        completionHandler: completionHandler
      )
    }
  }

  static func suspension(_ suspension: FilterSuspension) {
    if let data = suspension.jsonData {
      filter?.receiveSuspension(data, for: getuid())
    }
  }

  static func cancelSuspension() {
    filter?.cancelSuspension(for: getuid())
  }

  static func getRecentFilterDecisions(_ handler: @escaping ([Data]) -> Void) {
    filter?.transmitRecentFilterDecisions(handler)
  }

  static func getCurrentExemptUserIds(_ handler: @escaping (Set<uid_t>) -> Void) {
    filter?.transmitCurrentExemptUsers(handler)
  }

  static func exemptUserIds(_ commaSeparated: String) {
    filter?.receiveExemptUsers(commaSeparated)
  }

  static func removeAllExemptUsers() {
    filter?.removeAllExemptUsers()
  }

  static func purgeAllDeviceStorage() {
    filter?.purgeAllDeviceStorage()
  }

  static func loggingCommand(_ command: AppToFilterLoggingCommand) {
    if let data = command.jsonData {
      filter?.receiveLoggingCommand(data)
    }
  }

  static func getVersionString(_ handler: @escaping (String) -> Void) {
    filter?.transmitCurrentVersion(handler)
  }

  static func getNumKeysLoaded(for userId: uid_t, handler: @escaping (Int?) -> Void) {
    guard let filter = filter else {
      handler(nil)
      return
    }
    filter.transmitNumKeysLoaded(for: userId) { numKeys in
      handler(numKeys)
    }
  }

  static func communicationTest(_ handler: @escaping (Bool) -> Void) {
    guard let filter = filter else {
      handler(false)
      return
    }

    var timedOut = false
    var receivedFilterResponse = false

    let timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
      guard !receivedFilterResponse else { return }
      timedOut = true
      handler(false)
    }

    let sent = Int.random(in: Int.min ... Int.max)
    filter.receiveConfirmCommunication(int: sent) { received in
      guard !timedOut else { return }
      receivedFilterResponse = true
      timer.invalidate()
      handler(received == sent)
    }
  }
}

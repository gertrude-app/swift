import Foundation

@objc(ReceiveAppMessageInterface) public protocol ReceiveAppMessageInterface {
  func register(_ completionHandler: @escaping (Bool) -> Void)

  func receiveRefreshedRulesData(
    userId: uid_t,
    keys: [Data],
    idManifest: Data,
    completionHandler: @escaping (Bool) -> Void
  )

  func transmitRecentFilterDecisions(_ handler: @escaping ([Data]) -> Void)
  func transmitCurrentExemptUsers(_ handler: @escaping (Set<uid_t>) -> Void)
  func receiveExemptUsers(_ commaSeparated: String)
  func removeAllExemptUsers()
  func receiveSuspension(_ suspensionData: Data, for: uid_t)
  func cancelSuspension(for: uid_t)
  func transmitCurrentVersion(_ handler: @escaping (String) -> Void)
  func transmitNumKeysLoaded(for: uid_t, handler: @escaping (Int) -> Void)
  func receiveConfirmCommunication(int: Int, handler: @escaping (Int) -> Void)
  func receiveLoggingCommand(_ notificationData: Data)
  func purgeAllDeviceStorage()
}

@objc(ReceiveFilterMessageInterface) public protocol ReceiveFilterMessageInterface {
  func receiveLog(_ log: Data)
  func receiveBatchedHoneycombLogs(_ logs: [Data], completionHandler: @escaping (Bool) -> Void)
  func receiveRecentFilterDecisions(_ networkDecisions: [Data])
}

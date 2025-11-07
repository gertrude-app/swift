import Foundation

public typealias XPCErrorData = Data

@objc public protocol AppMessageReceiving {
  func receiveAckRequest(
    randomInt: Int,
    userId: uid_t,
    reply: @escaping (Data?, XPCErrorData?) -> Void,
  )
  func receiveAlive(
    for userId: uid_t,
    reply: @escaping (Bool, XPCErrorData?) -> Void,
  )
  func receiveListUserTypesRequest(
    reply: @escaping (Data?, XPCErrorData?) -> Void,
  )
  func receiveUserRules(
    userId: uid_t,
    manifestData: Data,
    filterData: Data,
    reply: @escaping (XPCErrorData?) -> Void,
  )
  func pauseDowntime(
    for userId: uid_t,
    until secondsSinceReference: Double,
    reply: @escaping (XPCErrorData?) -> Void,
  )
  func endDowntimePause(
    for userId: uid_t,
    reply: @escaping (XPCErrorData?) -> Void,
  )
  func setBlockStreaming(
    _ enabled: Bool,
    userId: uid_t,
    reply: @escaping (XPCErrorData?) -> Void,
  )
  func disconnectUser(
    _ userId: uid_t,
    reply: @escaping (XPCErrorData?) -> Void,
  )
  func setUserExemption(
    _ userId: uid_t,
    enabled: Bool,
    reply: @escaping (XPCErrorData?) -> Void,
  )
  func suspendFilter(
    for userId: uid_t,
    durationInSeconds: Int,
    reply: @escaping (XPCErrorData?) -> Void,
  )
  func endSuspension(
    for userId: uid_t,
    reply: @escaping (XPCErrorData?) -> Void,
  )
  func deleteAllStoredState(
    reply: @escaping (XPCErrorData?) -> Void,
  )
}

@objc public protocol FilterMessageReceiving {
  func receiveBlockedRequest(
    _ requestData: Data,
    userId: uid_t,
    reply: @escaping (XPCErrorData?) -> Void,
  )
  func receiveUserFilterSuspensionEnded(
    userId: uid_t,
    reply: @escaping (XPCErrorData?) -> Void,
  )
  func receiveFilterLogs(
    _ logs: Data,
    reply: @escaping (XPCErrorData?) -> Void,
  )
}

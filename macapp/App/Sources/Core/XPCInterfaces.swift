import Foundation

public typealias XPCErrorData = Data

@objc public protocol AppMessageReceiving {
  func receiveAckRequest(
    randomInt: Int,
    userId: uid_t,
    reply: @escaping (Data?, XPCErrorData?) -> Void
  )
  func receiveListExemptUserIdsRequest(
    reply: @escaping (Data?, XPCErrorData?) -> Void
  )
  func receiveUserRules(
    userId: uid_t,
    manifestData: Data,
    keysData: [Data],
    reply: @escaping (XPCErrorData?) -> Void
  )
  func setBlockStreaming(
    _ enabled: Bool,
    userId: uid_t,
    reply: @escaping (XPCErrorData?) -> Void
  )
  func disconnectUser(
    _ userId: uid_t,
    reply: @escaping (XPCErrorData?) -> Void
  )
  func setUserExemption(
    _ userId: uid_t,
    enabled: Bool,
    reply: @escaping (XPCErrorData?) -> Void
  )
  func suspendFilter(
    for userId: uid_t,
    durationInSeconds: Int,
    reply: @escaping (XPCErrorData?) -> Void
  )
  func endSuspension(
    for userId: uid_t,
    reply: @escaping (XPCErrorData?) -> Void
  )
  func deleteAllStoredState(
    reply: @escaping (XPCErrorData?) -> Void
  )
}

@objc public protocol FilterMessageReceiving {
  func receiveBlockedRequest(
    _ requestData: Data,
    userId: uid_t,
    reply: @escaping (XPCErrorData?) -> Void
  )
  func receiveUserFilterSuspensionEnded(
    userId: uid_t,
    reply: @escaping (XPCErrorData?) -> Void
  )
}

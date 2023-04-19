import Foundation

public typealias XPCErrorData = Data

@objc public protocol AppMessageReceiving {
  func ackRandomInt(_ intData: Data, reply: @escaping (Data?, XPCErrorData?) -> Void)
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
}

@objc public protocol FilterMessageReceiving {
  func receiveBlockedRequest(
    _ requestData: Data,
    userId: uid_t,
    reply: @escaping (XPCErrorData?) -> Void
  )
}

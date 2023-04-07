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
}

@objc public protocol FilterMessageReceiving {
  func receiveUuid(_ uuidData: Data, reply: @escaping (XPCErrorData?) -> Void)
}

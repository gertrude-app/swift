import Foundation

@objc public protocol AppMessageReceiving {
  func ackRandomInt(_ intData: Data, reply: @escaping (Data?, Error?) -> Void)
}

@objc public protocol FilterMessageReceiving {
  func ackRandomInt(_ intData: Data, reply: @escaping (Data?, Error?) -> Void)
}

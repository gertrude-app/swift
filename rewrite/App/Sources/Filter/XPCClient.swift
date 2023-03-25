import Core
import Dependencies
import Foundation

import os.log // temp

struct XPCClient: Sendable {
  var startListener: @Sendable () async -> Void
}

extension XPCClient: DependencyKey {
  static var liveValue: Self {
    let manager = ThreadSafe(XPCManager())
    return .init(
      startListener: { manager.value.startListener() }
    )
  }
}

extension XPCClient: TestDependencyKey {
  static let testValue = Self(
    startListener: {}
  )
}

extension DependencyValues {
  var xpc: XPCClient {
    get { self[XPCClient.self] }
    set { self[XPCClient.self] = newValue }
  }
}

// TODO: moveme
class XPCManager: NSObject, NSXPCListenerDelegate {
  var listener: NSXPCListener?

  // TODO: test if we can make a map keyed by user id
  var connection: NSXPCConnection?

  func startListener() {
    let newListener = NSXPCListener(machServiceName: Constants.MACH_SERVICE_NAME)
    newListener.delegate = self
    newListener.resume()
    listener = newListener
    os_log("[G•] XPCManager: started listener")
  }

  func listener(
    _ listener: NSXPCListener,
    shouldAcceptNewConnection newConnection: NSXPCConnection
  ) -> Bool {

    os_log("[G•] XPCManager: shouldAcceptNewConnection")
    newConnection.exportedInterface = NSXPCInterface(with: AppMessageReceiving.self)
    newConnection.exportedObject = self // Any?
    newConnection.remoteObjectInterface = NSXPCInterface(with: FilterMessageReceiving.self)

    // TODO: invalidation and interruption handlers

    connection = newConnection
    newConnection.resume()
    return true
  }
}

extension XPCManager: AppMessageReceiving {
  func ackRandomInt(_ intData: Data, reply: @escaping (Data?, Error?) -> Void) {
    do {
      let int = try JSONDecoder().decode(Int.self, from: intData)
      os_log("[G•] XPCManager: ackRandomInt: %{public}d", int)
      reply(try JSONEncoder().encode(int), nil)
    } catch {
      reply(nil, error)
    }
  }
}

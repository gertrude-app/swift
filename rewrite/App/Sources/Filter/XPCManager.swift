import Core
import Dependencies
import Foundation
import os.log

class XPCManager: NSObject, NSXPCListenerDelegate, XPCSender {
  typealias Proxy = FilterMessageReceiving

  var listener: NSXPCListener?
  var connection: ThreadSafe<NSXPCConnection>?

  @Dependency(\.mainQueue) var scheduler

  func sendUuid() async throws {
    guard let connection else {
      throw XPCErr.noConnection
    }
    let uuid = UUID()
    os_log("[G•] XPCManager: sending uuid: %{public}@", uuid.uuidString)
    let uuidData = try XPC.encode(uuid)
    try await withTimeout(connection: connection) { appProxy, continuation in
      appProxy.receiveUuid(uuidData, reply: continuation.resumingHandler)
    }
  }

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
    // NB: we can get user id: `newConnection.effectiveUserIdentifier`
    connection = ThreadSafe(configure(connection: newConnection))
    return true
  }
}

@objc class ReceiveAppMessage: NSObject, AppMessageReceiving {
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

func configure(connection: NSXPCConnection) -> NSXPCConnection {
  connection.exportedInterface = NSXPCInterface(with: AppMessageReceiving.self)
  connection.exportedObject = ReceiveAppMessage()
  connection.remoteObjectInterface = NSXPCInterface(with: FilterMessageReceiving.self)
  connection.resume()
  return connection
}

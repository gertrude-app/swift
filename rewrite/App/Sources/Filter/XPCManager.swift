import Core
import Dependencies
import Foundation
import os.log

class XPCManager: NSObject, NSXPCListenerDelegate, XPCSender {
  typealias Proxy = FilterMessageReceiving

  var listener: NSXPCListener?
  var connection: Connection?

  @Dependency(\.mainQueue) var scheduler

  func sendUuid() async throws {
    guard let connection else {
      throw XPCErr.noConnection
    }

    let uuid = UUID()
    os_log("[G•] XPCManager: sending uuid: %{public}@", uuid.uuidString)
    let uuidData = try XPC.encode(uuid)
    try await withTimeout(connection: connection) { appProxy, continuation in
      appProxy.receiveUuid(uuidData, reply: continuation.dataHandler)
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
    // ⛔️⛔️⛔️ WARNING ⛔️⛔️⛔️ `newConnection` has been "moved" into
    // the Connection object, and may not be accessed again !!!
    connection = Connection(taking: Move(configure(connection: newConnection)))
    return true
    // NB: we can get user id: `newConnection.effectiveUserIdentifier`
  }
}

func configure(connection: NSXPCConnection) -> NSXPCConnection {
  connection.exportedInterface = NSXPCInterface(with: AppMessageReceiving.self)
  connection.exportedObject = ReceiveAppMessage()
  connection.remoteObjectInterface = NSXPCInterface(with: FilterMessageReceiving.self)
  connection.resume()
  return connection
}

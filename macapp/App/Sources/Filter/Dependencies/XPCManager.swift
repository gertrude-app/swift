import Core
import Dependencies
import Foundation
import os.log

class XPCManager: NSObject, NSXPCListenerDelegate, XPCSender {
  typealias Proxy = FilterMessageReceiving

  var listener: NSXPCListener?
  var connection: Connection?

  @Dependency(\.mainQueue) var scheduler

  func notifyFilterSuspensionEnded(for userId: uid_t) async throws {
    guard let connection else {
      throw XPCErr.noConnection
    }

    os_log("[G•] XPCManager: notifying filter suspension ended: %{public}d", userId)
    try await withTimeout(connection: connection) { appProxy, continuation in
      appProxy.receiveUserFilterSuspensionEnded(userId: userId, reply: continuation.dataHandler)
    }
  }

  func sendBlockedRequest(_ request: BlockedRequest, userId: uid_t) async throws {
    guard let connection else {
      throw XPCErr.noConnection
    }

    os_log("[G•] XPCManager: sending blocked request: %{public}@", String(describing: request))
    let requestData = try XPC.encode(request)
    try await withTimeout(connection: connection) { appProxy, continuation in
      appProxy.receiveBlockedRequest(requestData, userId: userId, reply: continuation.dataHandler)
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
  connection.exportedObject = ReceiveAppMessage(subject: xpcEventSubject)
  connection.remoteObjectInterface = NSXPCInterface(with: FilterMessageReceiving.self)
  connection.resume()
  return connection
}

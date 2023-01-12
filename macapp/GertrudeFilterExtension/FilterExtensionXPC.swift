import Foundation
import SharedCore

class FilterExtensionXPC: NSObject, NSXPCListenerDelegate {
  static let shared = FilterExtensionXPC()
  var listener: NSXPCListener?
  var connection: NSXPCConnection?
  private var _appReceiver: ReceiveFilterMessageInterface?

  func startListener() {
    log(.xpcDelegate(.startListener))
    let newListener = NSXPCListener(machServiceName: SharedConstants.MACH_SERVICE_NAME)
    newListener.delegate = self
    newListener.resume()
    listener = newListener
  }

  func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection)
    -> Bool {
    newConnection.exportedInterface = NSXPCInterface(with: ReceiveAppMessageInterface.self)
    newConnection.exportedObject = ReceiveAppMessage()
    newConnection.remoteObjectInterface = NSXPCInterface(with: ReceiveFilterMessageInterface.self)

    newConnection.invalidationHandler = {
      log(.xpcDelegate(.invalidationHandlerInvoked))
      self.destroyConnection()
    }

    newConnection.interruptionHandler = {
      log(.xpcDelegate(.interruptionHandlerInvoked))
      self.destroyConnection()
    }

    connection = newConnection
    newConnection.resume()
    log(.xpcDelegate(.newConnection))
    return true
  }

  var appReceiver: ReceiveFilterMessageInterface? {
    if let receiver = _appReceiver {
      return receiver
    }

    guard let conn = connection else {
      // the App isn't connected right now, so there's no one to talk to, and
      // the filter extension can't initiate contact with the app, only app->extension
      return nil
    }

    let proxy = conn.remoteObjectProxyWithErrorHandler { err in
      log(.xpcDelegate(.remoteObjectProxyError(err)))
      self.destroyConnection()
    }

    guard let receiver = proxy as? ReceiveFilterMessageInterface else {
      fatalError("[GERTIE] Failed to create remote (app-side) receiver proxy")
    }

    _appReceiver = receiver
    return receiver
  }

  private func destroyConnection() {
    connection?.invalidate()
    connection = nil
    _appReceiver = nil
  }
}

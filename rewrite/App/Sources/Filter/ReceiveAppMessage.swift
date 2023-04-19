import Combine
import Core
import Foundation
import os.log // TODO: remove when logging in place
import Shared

@objc class ReceiveAppMessage: NSObject, AppMessageReceiving {
  let subject: Mutex<PassthroughSubject<XPCEvent.Filter, Never>>

  init(subject: Mutex<PassthroughSubject<XPCEvent.Filter, Never>>) {
    self.subject = subject
  }

  func ackRandomInt(_ intData: Data, reply: @escaping (Data?, XPCErrorData?) -> Void) {
    do {
      let int = try XPC.decode(Int.self, from: intData)
      os_log("[G•] XPCManager (new): ackRandomInt: %{public}d", int)
      reply(try XPC.encode(int), nil)
    } catch {
      os_log("[G•] XPCManager: error %{public}@", "\(error)")
      reply(nil, XPC.errorData(error))
    }
  }

  func receiveUserRules(
    userId: uid_t,
    manifestData: Data,
    keysData: [Data],
    reply: @escaping (XPCErrorData?) -> Void
  ) {
    do {
      let manifest = try XPC.decode(AppIdManifest.self, from: manifestData)
      let keys = try keysData.map { try XPC.decode(FilterKey.self, from: $0) }
      subject.withValue {
        $0.send(.receivedAppMessage(.userRules(
          userId: userId,
          keys: keys,
          manifest: manifest
        )))
      }
      os_log(
        "[G•] XPCManager: received user rules, user: %{public}d, num keys: %{public}d",
        userId,
        keys.count
      )
      reply(nil)
    } catch {
      os_log("[G•] XPCManager: error %{public}@", "\(error)")
      reply(XPC.errorData(error))
    }
  }

  func setBlockStreaming(
    _ enabled: Bool,
    userId: uid_t,
    reply: @escaping (XPCErrorData?) -> Void
  ) {
    subject.withValue {
      $0.send(.receivedAppMessage(.setBlockStreaming(enabled: enabled, userId: userId)))
    }
    os_log(
      "[G•] XPCManager: setBlockStreaming enabled=%{public}d, userId: %{public}d",
      enabled,
      userId
    )
    reply(nil)
  }
}

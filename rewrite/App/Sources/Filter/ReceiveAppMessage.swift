import Combine
import Core
import Dependencies
import Foundation
import os.log // TODO: remove when logging in place
import Shared

@objc class ReceiveAppMessage: NSObject, AppMessageReceiving {
  let subject: Mutex<PassthroughSubject<XPCEvent.Filter, Never>>

  @Dependency(\.storage) var storage

  init(subject: Mutex<PassthroughSubject<XPCEvent.Filter, Never>>) {
    self.subject = subject
  }

  func receiveAckRequest(
    randomInt: Int,
    userId: uid_t,
    reply: @escaping (Data?, XPCErrorData?) -> Void
  ) {
    do {
      os_log(
        "[G•] XPCManager (new): receiveAckRequest, int: %{public}d, userId: %{public}d",
        randomInt,
        userId
      )
      let savedState = try storage.loadPersistentState()
      let version = Bundle.main
        .infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
      let ack = XPC.FilterAck(
        randomInt: randomInt,
        version: Bool.random() ? "0.9.777" : version,
        userId: userId,
        // 👍 change me back!!!!!!!
        numUserKeys: Bool.random() ? 0 : savedState?.userKeys[userId]?.count ?? 0
      )
      let data = try XPC.encode(ack)
      reply(data, nil)
    } catch {
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

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

  func setUserExemption(
    _ userId: uid_t,
    enabled: Bool,
    reply: @escaping (XPCErrorData?) -> Void
  ) {
    os_log(
      "[G•] xpc.setUserExemption(%{public}d, enabled: %{public}s)",
      userId,
      enabled ? "true" : "false"
    )
    subject.withValue {
      $0.send(.receivedAppMessage(.setUserExemption(userId: userId, enabled: enabled)))
    }
    reply(nil)
  }

  func disconnectUser(_ userId: uid_t, reply: @escaping (XPCErrorData?) -> Void) {
    os_log("[G•] xpc.disconnectUser(for: %{public}d)", userId)
    subject.withValue {
      $0.send(.receivedAppMessage(.disconnectUser(userId: userId)))
    }
    reply(nil)
  }

  func endSuspension(for userId: uid_t, reply: @escaping (XPCErrorData?) -> Void) {
    os_log("[G•] xpc.endSuspension(for: %{public}d)", userId)
    subject.withValue {
      $0.send(.receivedAppMessage(.endFilterSuspension(userId: userId)))
    }
    reply(nil)
  }

  func suspendFilter(
    for userId: uid_t,
    durationInSeconds: Int,
    reply: @escaping (XPCErrorData?) -> Void
  ) {
    os_log(
      "[G•] xpc.suspendFilter(userId: %{public}d, seconds: %{public}d)",
      userId,
      durationInSeconds
    )
    subject.withValue {
      $0.send(.receivedAppMessage(.suspendFilter(
        userId: userId,
        duration: .init(durationInSeconds)
      )))
    }
    reply(nil)
  }

  func receiveAckRequest(
    randomInt: Int,
    userId: uid_t,
    reply: @escaping (Data?, XPCErrorData?) -> Void
  ) {
    do {
      os_log(
        "[G•] xpc.receiveAckRequest(randomInt: %{public}d, userId: %{public}d)",
        randomInt,
        userId
      )
      let savedState = try storage.loadPersistentState()
      let version = Bundle.main
        .infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
      let ack = XPC.FilterAck(
        randomInt: randomInt,
        version: version,
        userId: userId,
        numUserKeys: savedState?.userKeys[userId]?.count ?? 0
      )
      let data = try XPC.encode(ack)
      reply(data, nil)
    } catch {
      os_log("[G•] xpc.receiveAckRequest error: %{public}@", "\(error)")
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
        "[G•] xpc.receiveUserRules(userId: %{public}d,...) num keys: %{public}d",
        userId,
        keys.count
      )
      reply(nil)
    } catch {
      os_log("[G•] xpc.receiveUserRules error: %{public}@", "\(error)")
      reply(XPC.errorData(error))
    }
  }

  func receiveListExemptUserIdsRequest(
    reply: @escaping (Data?, XPCErrorData?) -> Void
  ) {
    do {
      os_log("[G•] xpc.receiveListExemptUserIdsRequest()")
      let savedState = try storage.loadPersistentState()
      let exemptUsers = Array(savedState?.exemptUsers ?? [])
      let data = try XPC.encode(exemptUsers)
      reply(data, nil)
    } catch {
      os_log("[G•] xpc.receiveListExemptUserIdsRequest() error: %{public}@", "\(error)")
      reply(nil, XPC.errorData(error))
    }
  }

  func setBlockStreaming(
    _ enabled: Bool,
    userId: uid_t,
    reply: @escaping (XPCErrorData?) -> Void
  ) {
    os_log(
      "[G•] xpc.setBlockStreaming(%{public}s, userId: %{public}d)",
      enabled ? "true" : "false",
      userId
    )
    subject.withValue {
      $0.send(.receivedAppMessage(.setBlockStreaming(enabled: enabled, userId: userId)))
    }
    reply(nil)
  }

  func prepareForUninstall(reply: @escaping (XPCErrorData?) -> Void) {
    os_log("[G•] xpc.prepareForUninstall()")
    subject.withValue {
      $0.send(.receivedAppMessage(.prepareForUninstall))
    }
    reply(nil)
  }
}

import Combine
import Core
import Dependencies
import Foundation
import Gertie
import os.log

@objc class ReceiveAppMessage: NSObject, AppMessageReceiving {
  let subject: Mutex<PassthroughSubject<XPCEvent.Filter, Never>>

  @Dependency(\.storage) var storage
  @Dependency(\.filterExtension) var filterExtension

  init(subject: Mutex<PassthroughSubject<XPCEvent.Filter, Never>>) {
    self.subject = subject
  }

  func setUserExemption(
    _ userId: uid_t,
    enabled: Bool,
    reply: @escaping (XPCErrorData?) -> Void
  ) {
    os_log(
      "[G•] FILTER xpc.setUserExemption(%{public}d, enabled: %{public}s)",
      userId,
      enabled ? "true" : "false"
    )
    self.subject.withValue {
      $0.send(.receivedAppMessage(.setUserExemption(userId: userId, enabled: enabled)))
    }
    reply(nil)
  }

  func disconnectUser(_ userId: uid_t, reply: @escaping (XPCErrorData?) -> Void) {
    os_log("[G•] FILTER xpc.disconnectUser(for: %{public}d)", userId)
    self.subject.withValue {
      $0.send(.receivedAppMessage(.disconnectUser(userId: userId)))
    }
    reply(nil)
  }

  func endSuspension(for userId: uid_t, reply: @escaping (XPCErrorData?) -> Void) {
    os_log("[G•] FILTER xpc.endSuspension(for: %{public}d)", userId)
    self.subject.withValue {
      $0.send(.receivedAppMessage(.endFilterSuspension(userId: userId)))
    }
    reply(nil)
  }

  func pauseDowntime(
    for userId: uid_t,
    until secondsSinceReference: Double,
    reply: @escaping (XPCErrorData?) -> Void
  ) {
    let expiration = Date(timeIntervalSinceReferenceDate: secondsSinceReference)
    os_log(
      "[G•] FILTER xpc.pauseDowntime(for: %{public}d, until: %{public}s)",
      userId,
      expiration.description
    )
    self.subject.withValue {
      $0.send(.receivedAppMessage(.pauseDowntime(userId: userId, until: expiration)))
    }
    reply(nil)
  }

  func endDowntimePause(
    for userId: uid_t,
    reply: @escaping (XPCErrorData?) -> Void
  ) {
    os_log("[G•] FILTER xpc.endDowntimePause(for: %{public}d)", userId)
    self.subject.withValue {
      $0.send(.receivedAppMessage(.endDowntimePause(userId: userId)))
    }
    reply(nil)
  }

  func suspendFilter(
    for userId: uid_t,
    durationInSeconds: Int,
    reply: @escaping (XPCErrorData?) -> Void
  ) {
    os_log(
      "[G•] FILTER xpc.suspendFilter(userId: %{public}d, seconds: %{public}d)",
      userId,
      durationInSeconds
    )
    self.subject.withValue {
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
        "[G•] FILTER xpc.receiveAckRequest(randomInt: %{public}d, userId: %{public}d)",
        randomInt,
        userId
      )
      let savedState = try storage.loadPersistentStateSync()
      let ack = XPC.FilterAck(
        randomInt: randomInt,
        version: self.filterExtension.version(),
        userId: userId,
        numUserKeys: savedState?.userKeychains[userId]?.numKeys ?? 0
      )
      let data = try XPC.encode(ack)
      reply(data, nil)
    } catch {
      os_log("[G•] FILTER xpc.receiveAckRequest error: %{public}@", "\(error)")
      reply(nil, XPC.errorData(error))
    }
  }

  func receiveUserRules(
    userId: uid_t,
    manifestData: Data,
    filterData: Data,
    reply: @escaping (XPCErrorData?) -> Void
  ) {
    do {
      let manifest = try XPC.decode(AppIdManifest.self, from: manifestData)
      let userData = try XPC.decode(UserFilterData.self, from: filterData)
      self.subject.withValue { $0.send(.receivedAppMessage(.userRules(
        userId: userId,
        keychains: userData.keychains,
        downtime: userData.downtime,
        manifest: manifest
      ))) }
      os_log(
        "[G•] FILTER xpc.receiveUserRules(userId: %{public}d,...) num keys: %{public}d",
        userId,
        userData.keychains.numKeys
      )
      reply(nil)
    } catch {
      os_log("[G•] FILTER xpc.receiveUserRules error: %{public}@", "\(error)")
      reply(XPC.errorData(error))
    }
  }

  func receiveListUserTypesRequest(reply: @escaping (Data?, XPCErrorData?) -> Void) {
    do {
      os_log("[G•] FILTER xpc.receiveListUserTypesRequest()")
      let savedState = try storage.loadPersistentStateSync()
      let exemptUsers = Array(savedState?.exemptUsers ?? [])
      let protectedUsers = savedState.map { Array($0.userKeychains.keys) } ?? []
      let data = try XPC.encode(FilterUserTypes(exempt: exemptUsers, protected: protectedUsers))
      reply(data, nil)
    } catch {
      os_log("[G•] FILTER xpc.receiveListUserTypesRequest() error: %{public}@", "\(error)")
      reply(nil, XPC.errorData(error))
    }
  }

  func setBlockStreaming(
    _ enabled: Bool,
    userId: uid_t,
    reply: @escaping (XPCErrorData?) -> Void
  ) {
    os_log(
      "[G•] FILTER xpc.setBlockStreaming(%{public}s, userId: %{public}d)",
      enabled ? "true" : "false",
      userId
    )
    self.subject.withValue {
      $0.send(.receivedAppMessage(.setBlockStreaming(enabled: enabled, userId: userId)))
    }
    reply(nil)
  }

  func deleteAllStoredState(reply: @escaping (XPCErrorData?) -> Void) {
    os_log("[G•] FILTER xpc.deleteAllStoredState()")
    self.subject.withValue {
      $0.send(.receivedAppMessage(.deleteAllStoredState))
    }
    reply(nil)
  }
}

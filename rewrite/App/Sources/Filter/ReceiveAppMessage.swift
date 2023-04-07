import Core
import Foundation
import os.log // TODO: remove when logging in place
import Shared

@objc class ReceiveAppMessage: NSObject, AppMessageReceiving {
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
      _ = try XPC.decode(AppIdManifest.self, from: manifestData)
      let keys = try keysData.map { try XPC.decode(FilterKey.self, from: $0) }
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
}

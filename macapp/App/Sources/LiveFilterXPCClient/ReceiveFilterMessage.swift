import ClientInterfaces
import Combine
import Core
import Foundation

@objc class ReceiveFilterMessage: NSObject, FilterMessageReceiving {

  let subject: Mutex<PassthroughSubject<XPCEvent.App, Never>>

  init(subject: Mutex<PassthroughSubject<XPCEvent.App, Never>>) {
    self.subject = subject
  }

  func receiveUserFilterSuspensionEnded(
    userId: uid_t,
    reply: @escaping (XPCErrorData?) -> Void
  ) {
    self.subject.withValue {
      $0.send(.receivedExtensionMessage(.userFilterSuspensionEnded(userId)))
    }
    reply(nil)
  }

  func receiveBlockedRequest(
    _ requestData: Data,
    userId: uid_t,
    reply: @escaping (Core.XPCErrorData?) -> Void
  ) {
    guard userId == getuid() else {
      reply(nil)
      return
    }
    do {
      let request = try JSONDecoder().decode(BlockedRequest.self, from: requestData)
      self.subject.withValue {
        $0.send(.receivedExtensionMessage(.blockedRequest(request)))
      }
      reply(nil)
    } catch {
      self.subject.withValue {
        $0.send(.decodingExtensionMessageDataFailed(
          fn: "\(#function)",
          type: "\(BlockedRequest.self)",
          error: "\(error)"
        ))
      }
      reply(XPC.errorData(error))
    }
  }
}

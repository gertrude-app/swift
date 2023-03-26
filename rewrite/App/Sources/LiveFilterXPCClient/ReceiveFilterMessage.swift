import Combine
import Core
import Foundation
import Models

@objc class ReceiveFilterMessage: NSObject, FilterMessageReceiving {
  let subject: ThreadSafe<PassthroughSubject<XPCEvent, Never>>

  init(subject: ThreadSafe<PassthroughSubject<XPCEvent, Never>>) {
    self.subject = subject
  }

  func receiveUuid(_ uuidData: Data, reply: @escaping (Error?) -> Void) {
    do {
      let uuid = try JSONDecoder().decode(UUID.self, from: uuidData)
      subject.unlock().send(.receivedExtensionMessage(.uuid(uuid)))
      reply(nil)
    } catch {
      subject.unlock().send(.decodingExtensionDataFailed(
        fn: "\(#function)",
        type: "\(UUID.self)",
        error: "\(error)"
      ))
      reply(error)
    }
  }
}

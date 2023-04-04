import Combine
import Core
import Foundation
import Models

@objc class ReceiveFilterMessage: NSObject, FilterMessageReceiving {
  let subject: Mutex<PassthroughSubject<XPCEvent, Never>>

  init(subject: Mutex<PassthroughSubject<XPCEvent, Never>>) {
    self.subject = subject
  }

  func receiveUuid(_ uuidData: Data, reply: @escaping (Error?) -> Void) {
    do {
      let uuid = try JSONDecoder().decode(UUID.self, from: uuidData)
      // subject.unlock().send(.receivedExtensionMessage(.uuid(uuid)))
      subject.withValue { $0.send(.receivedExtensionMessage(.uuid(uuid))) }
      reply(nil)
    } catch {
      subject.withValue {
        $0.send(.decodingExtensionDataFailed(
          fn: "\(#function)",
          type: "\(UUID.self)",
          error: "\(error)"
        ))
      }
      reply(error)
    }
  }
}

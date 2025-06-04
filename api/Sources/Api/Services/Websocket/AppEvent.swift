import Foundation
import Gertie
import TaggedTime

struct AppEvent: Equatable {
  enum Matcher: Equatable {
    case user(Child.Id)
    case usersWith(keychain: Keychain.Id)
    case userDevice(ComputerUser.Id)
  }

  var matcher: Matcher
  var message: WebSocketMessage.FromApiToApp
}

extension AppConnection.Ids {
  func satisfies(matcher: AppEvent.Matcher) -> Bool {
    switch matcher {
    case .user(let userId):
      self.user == userId
    case .usersWith(let keychainId):
      self.keychains.contains(keychainId)
    case .userDevice(let userDeviceId):
      self.userDevice == userDeviceId
    }
  }
}

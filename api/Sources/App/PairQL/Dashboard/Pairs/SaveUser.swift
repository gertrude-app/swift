import Foundation
import TypescriptPairQL

struct SaveUser: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Input: TypescriptPairInput {
    var id: UUID
    var adminId: UUID
    var isNew: Bool
    var name: String
    var keyloggingEnabled: Bool
    var screenshotsEnabled: Bool
    var screenshotsResolution: Int
    var screenshotsFrequency: Int
    var keychainIds: [UUID]
  }
}

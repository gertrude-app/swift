import DuetSQL
import TypescriptPairQL
import Vapor

struct DeleteEntity: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Input: TypescriptPairInput {
    let id: UUID
    let type: String
  }
}

// resolver

extension DeleteEntity: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    switch input.type {

    case "AdminNotification":
      try await Current.db.query(AdminNotification.self)
        .where(.id == input.id)
        .where(.adminId == context.admin.id)
        .delete()

    case "AdminVerifiedNotificationMethod":
      try await Current.db.query(AdminVerifiedNotificationMethod.self)
        .where(.id == input.id)
        .where(.adminId == context.admin.id)
        .delete()

    case "Device":
      let device = try await Current.db.find(Device.Id(input.id))
      try await context.verifiedUser(from: device.userId)
      try await Current.db.delete(device.id)

    case "Key":
      let key = try await Current.db.find(Key.Id(input.id))
      let keychain = try await key.keychain()
      guard keychain.authorId == context.admin.id else {
        throw Abort(.unauthorized)
      }
      try await Current.db.delete(key.id)
      await Current.connectedApps.notify(.keychainUpdated(keychain.id))

    case "Keychain":
      try await Current.db.query(Keychain.self)
        .where(.id == input.id)
        .where(.authorId == context.admin.id)
        .delete()

    case "User":
      try await Current.db.query(User.self)
        .where(.id == input.id)
        .where(.adminId == context.admin.id)
        .delete()

    default:
      throw Abort(.badRequest, reason: "[@client:invalidDeleteEntityType]")
    }

    return .success
  }
}

// extensions

extension DeleteEntity.Input {
  static var customTs: String? {
    """
      export interface __self__ {
        id: UUID;
        type:
          | 'AdminNotification'
          | 'AdminVerifiedNotificationMethod'
          | 'Device'
          | 'Key'
          | 'Keychain'
          | 'User';
      }
    """
  }
}

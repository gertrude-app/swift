import DuetSQL
import PairQL
import Vapor

struct DeleteEntity: Pair {
  static var auth: ClientAuth = .admin

  struct Input: PairInput {
    enum EntityType: String, Codable {
      case adminNotification
      case adminVerifiedNotificationMethod
      case device
      case key
      case keychain
      case user
    }

    let id: UUID
    let type: EntityType
  }
}

// resolver

extension DeleteEntity: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    switch input.type {

    case .adminNotification:
      try await Current.db.query(AdminNotification.self)
        .where(.id == input.id)
        .where(.adminId == context.admin.id)
        .delete()

    case .adminVerifiedNotificationMethod:
      try await Current.db.query(AdminVerifiedNotificationMethod.self)
        .where(.id == input.id)
        .where(.adminId == context.admin.id)
        .delete()

    case .device:
      let device = try await Current.db.find(Device.Id(input.id))
      try await context.verifiedUser(from: device.userId)
      try await Current.db.delete(device.id)

    case .key:
      let key = try await Current.db.find(Key.Id(input.id))
      let keychain = try await key.keychain()
      guard keychain.authorId == context.admin.id else {
        throw Abort(.unauthorized)
      }
      try await Current.db.delete(key.id)
      try await Current.connectedApps.notify(.keychainUpdated(keychain.id))

    case .keychain:
      try await Current.db.query(Keychain.self)
        .where(.id == input.id)
        .where(.authorId == context.admin.id)
        .delete()

    case .user:
      try await Current.db.query(User.self)
        .where(.id == input.id)
        .where(.adminId == context.admin.id)
        .delete()
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

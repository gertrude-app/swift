import DuetSQL
import PairQL
import Vapor

struct DeleteEntity: Pair {
  static var auth: ClientAuth = .admin

  struct Input: PairInput {
    enum EntityType: String, Codable {
      case adminNotification
      case adminVerifiedNotificationMethod
      case userDevice
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

    case .userDevice:
      let userDevice = try await Current.db.find(UserDevice.Id(input.id))
      try await context.verifiedUser(from: userDevice.userId)
      try await Current.db.delete(userDevice.id)
      let remainingUserDevices = try await UserDevice.query()
        .where(.deviceId == userDevice.deviceId)
        .all()
      if remainingUserDevices.isEmpty {
        try await Current.db.delete(userDevice.deviceId)
      }

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
      let deviceIds = try await context.userDevices().map(\.deviceId)
      try await User.query()
        .where(.id == input.id)
        .where(.adminId == context.admin.id)
        .delete(force: true)
      let devices = try await Device.query()
        .where(.id |=| deviceIds)
        .all()
      for device in devices {
        if try await device.userDevices().isEmpty {
          try await Current.db.delete(device.id)
        }
      }
      try await Current.connectedApps.notify(.userDeleted(.init(input.id)))
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

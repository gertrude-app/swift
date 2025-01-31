import DuetSQL
import PairQL
import Vapor
import XCore

struct DeleteEntity: Pair {
  static let auth: ClientAuth = .admin

  struct Input: PairInput {
    enum EntityType: String, Codable {
      case admin
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
  static func resolve(
    with input: Input,
    in context: AdminContext
  ) async throws -> Output {
    switch input.type {
    case .admin:
      guard input.id == context.admin.id else {
        throw Abort(.unauthorized)
      }
      try await context.db.create(DeletedEntity(
        type: "Admin",
        reason: "self-deleted from use-case initial screen",
        data: try JSON.encode(context.admin, [.isoDates])
      ))
      try await context.db.delete(context.admin)

    case .adminNotification:
      try await AdminNotification.query()
        .where(.id == input.id)
        .where(.parentId == context.admin.id)
        .delete(in: context.db)
      dashSecurityEvent(.notificationDeleted, in: context)

    case .adminVerifiedNotificationMethod:
      try await AdminVerifiedNotificationMethod.query()
        .where(.id == input.id)
        .where(.parentId == context.admin.id)
        .delete(in: context.db)

    case .userDevice:
      let userDevice = try await context.db.find(UserDevice.Id(input.id))
      let device = try await context.db.find(userDevice.computerId)
      let user = try await context.verifiedUser(from: userDevice.childId)
      try await context.db.delete(userDevice)
      let remainingUserDevices = try await UserDevice.query()
        .where(.computerId == userDevice.computerId)
        .all(in: context.db)
      if remainingUserDevices.isEmpty {
        try await context.db.delete(userDevice.computerId)
      }
      dashSecurityEvent(
        .childComputerDeleted,
        "child: \(user.name), computer serial: \(device.serialNumber)",
        in: context
      )

    case .key:
      let key = try await context.db.find(Key.Id(input.id))
      let keychain = try await key.keychain(in: context.db)
      guard keychain.parentId == context.admin.id else {
        throw Abort(.unauthorized)
      }
      try await context.db.delete(key, force: true)
      try await with(dependency: \.websockets)
        .send(.userUpdated, to: .usersWith(keychain: keychain.id))

    case .keychain:
      try await Keychain.query()
        .where(.id == input.id)
        .where(.parentId == context.admin.id)
        .delete(in: context.db)

    case .user:
      let deviceIds = try await context.userDevices().map(\.computerId)
      let user = try await User.query()
        .where(.id == input.id)
        .where(.parentId == context.admin.id)
        .first(in: context.db)
      dashSecurityEvent(.childDeleted, "name: \(user.name)", in: context)

      let userKeychainIds = try await UserKeychain.query()
        .where(.childId == user.id)
        .all(in: context.db)
        .map(\.keychainId)

      try await context.db.delete(user)

      await deleteUnusedEmptyAutogenKeychain(userKeychainIds, context.db)

      let devices = try await Device.query()
        .where(.id |=| deviceIds)
        .all(in: context.db)
      for device in devices {
        if try await device.userDevices(in: context.db).isEmpty {
          try await context.db.delete(device)
        }
      }
      try await with(dependency: \.websockets)
        .send(.userDeleted, to: .user(user.id))
    }

    return .success
  }
}

func deleteUnusedEmptyAutogenKeychain(
  _ userKeychainIds: [Keychain.Id],
  _ db: any DuetSQL.Client
) async {
  do {
    let keychains = try await Keychain.query()
      .where(.id |=| userKeychainIds)
      .where(.like(.description, "%created automatically%"))
      .all(in: db)

    for keychain in keychains {
      let keys = try await keychain.keys(in: db)
      if keys.isEmpty {
        let otherUsers = try await UserKeychain.query()
          .where(.keychainId == keychain.id)
          .all(in: db)
        if otherUsers.isEmpty {
          try await db.delete(keychain)
        }
      }
    }
  } catch {
    // we don't care about errors, we're just cleaning up
    // after ourselves, there's no harm if this operation fails
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

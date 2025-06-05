import DuetSQL
import PairQL
import Vapor
import XCore

// deprecated: delete after 6/14/25
struct DeleteEntity: Pair {
  static let auth: ClientAuth = .parent

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
      guard input.id == context.parent.id else {
        throw Abort(.unauthorized)
      }
      try await context.db.create(DeletedEntity(
        type: "Admin",
        reason: "self-deleted from use-case initial screen",
        data: JSON.encode(context.parent, [.isoDates])
      ))
      try await context.db.delete(context.parent)

    case .adminNotification:
      try await AdminNotification.query()
        .where(.id == input.id)
        .where(.parentId == context.parent.id)
        .delete(in: context.db)
      dashSecurityEvent(.notificationDeleted, in: context)

    case .adminVerifiedNotificationMethod:
      try await AdminVerifiedNotificationMethod.query()
        .where(.id == input.id)
        .where(.parentId == context.parent.id)
        .delete(in: context.db)

    case .userDevice:
      let userDevice = try await context.db.find(ComputerUser.Id(input.id))
      let device = try await context.db.find(userDevice.computerId)
      let user = try await context.verifiedChild(from: userDevice.childId)
      try await context.db.delete(userDevice)
      let remainingComputerUsers = try await ComputerUser.query()
        .where(.computerId == userDevice.computerId)
        .all(in: context.db)
      if remainingComputerUsers.isEmpty {
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
      guard keychain.parentId == context.parent.id else {
        throw Abort(.unauthorized)
      }
      try await context.db.delete(key, force: true)
      try await with(dependency: \.websockets)
        .send(.userUpdated, to: .usersWith(keychain: keychain.id))

    case .keychain:
      try await Keychain.query()
        .where(.id == input.id)
        .where(.parentId == context.parent.id)
        .delete(in: context.db)

    case .user:
      let deviceIds = try await context.computerUsers().map(\.computerId)
      let child = try await Child.query()
        .where(.id == input.id)
        .where(.parentId == context.parent.id)
        .first(in: context.db)
      dashSecurityEvent(.childDeleted, "name: \(child.name)", in: context)

      let childKeychainIds = try await ChildKeychain.query()
        .where(.childId == child.id)
        .all(in: context.db)
        .map(\.keychainId)

      try await context.db.delete(child)

      await deleteUnusedEmptyAutogenKeychain(childKeychainIds, context.db)

      let devices = try await Computer.query()
        .where(.id |=| deviceIds)
        .all(in: context.db)
      for device in devices {
        if try await device.computerUsers(in: context.db).isEmpty {
          try await context.db.delete(device)
        }
      }
      try await with(dependency: \.websockets)
        .send(.userDeleted, to: .user(child.id))
    }

    return .success
  }
}

private func deleteUnusedEmptyAutogenKeychain(
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
        let otherUsers = try await ChildKeychain.query()
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

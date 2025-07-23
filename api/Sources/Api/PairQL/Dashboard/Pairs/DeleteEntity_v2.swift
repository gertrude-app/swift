import DuetSQL
import PairQL
import Vapor
import XCore

struct DeleteEntity_v2: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    enum EntityType: String, Codable {
      case announcement
      case child
      case computerUser
      case parent
      case parentNotification
      case parentVerifiedNotificationMethod
      case key
      case keychain
      case blockRule
    }

    let id: UUID
    let type: EntityType
  }
}

// resolver

extension DeleteEntity_v2: Resolver {
  static func resolve(
    with input: Input,
    in context: ParentContext
  ) async throws -> Output {
    switch input.type {
    case .announcement:
      try await DashAnnouncement.query()
        .where(.id == input.id)
        .where(.parentId == context.parent.id)
        .delete(in: context.db, force: true)

    case .parent:
      guard input.id == context.parent.id else {
        throw Abort(.unauthorized)
      }
      try await context.db.create(DeletedEntity(
        type: "Admin",
        reason: "self-deleted from use-case initial screen",
        data: JSON.encode(context.parent, [.isoDates])
      ))
      try await context.db.delete(context.parent)

    case .parentNotification:
      try await Parent.Notification.query()
        .where(.id == input.id)
        .where(.parentId == context.parent.id)
        .delete(in: context.db)
      dashSecurityEvent(.notificationDeleted, in: context)

    case .parentVerifiedNotificationMethod:
      try await Parent.NotificationMethod.query()
        .where(.id == input.id)
        .where(.parentId == context.parent.id)
        .delete(in: context.db)

    case .computerUser:
      let computerUser = try await context.db.find(ComputerUser.Id(input.id))
      let computer = try await context.db.find(computerUser.computerId)
      let child = try await context.verifiedChild(from: computerUser.childId)
      try await context.db.delete(computerUser)
      let remainingComputerUsers = try await ComputerUser.query()
        .where(.computerId == computerUser.computerId)
        .all(in: context.db)
      if remainingComputerUsers.isEmpty {
        try await context.db.delete(computerUser.computerId)
      }
      dashSecurityEvent(
        .childComputerDeleted,
        "child: \(child.name), computer serial: \(computer.serialNumber)",
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

    case .blockRule:
      let blockRule = try await context.db.find(IOSApp.BlockRule.Id(input.id))
      guard let device = try await blockRule.device(in: context.db) else {
        throw Abort(.unauthorized)
      }
      let child = try await device.child(in: context.db)
      if child.parentId != context.parent.id {
        throw Abort(.unauthorized)
      }
      try await context.db.delete(blockRule)
      dashSecurityEvent(.iosBlockRuleDeleted, "child: \(child.name)", in: context)

    case .child:
      let computerIds = try await context.computerUsers().map(\.computerId)
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

      let computers = try await Computer.query()
        .where(.id |=| computerIds)
        .all(in: context.db)
      for computer in computers {
        if try await computer.computerUsers(in: context.db).isEmpty {
          try await context.db.delete(computer)
        }
      }
      try await with(dependency: \.websockets)
        .send(.userDeleted, to: .user(child.id))
    }

    return .success
  }
}

private func deleteUnusedEmptyAutogenKeychain(
  _ childKeychainIds: [Keychain.Id],
  _ db: any DuetSQL.Client
) async {
  do {
    let keychains = try await Keychain.query()
      .where(.id |=| childKeychainIds)
      .where(.like(.description, "%created automatically%"))
      .all(in: db)

    for keychain in keychains {
      let keys = try await keychain.keys(in: db)
      if keys.isEmpty {
        let otherChildren = try await ChildKeychain.query()
          .where(.keychainId == keychain.id)
          .all(in: db)
        if otherChildren.isEmpty {
          try await db.delete(keychain)
        }
      }
    }
  } catch {
    // we don't care about errors, we're just cleaning up
    // after ourselves, there's no harm if this operation fails
  }
}

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
    case "User":
      try await Current.db.query(User.self)
        .where(.id == input.id)
        .where(.adminId == context.admin.id)
        .delete()

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

    default:
      throw Abort(.badRequest, reason: "[@client:invalidDeleteEntityType]")
    }

    return .success
  }
}

// extensions

extension DeleteEntity.Input {
  static var customTs = """
    export interface __self__ {
      id: UUID;
      type:
        | `User`
        | `AdminNotification`
        | `AdminVerifiedNotificationMethod`;
    }
  """
}

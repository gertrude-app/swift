import DuetSQL
import Foundation
import TypescriptPairQL

struct SaveNotification: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Input: TypescriptPairInput {
    let id: AdminNotification.Id
    let isNew: Bool
    let methodId: AdminVerifiedNotificationMethod.Id
    let trigger: AdminNotification.Trigger
  }
}

// resolver

extension SaveNotification: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    if !input.isNew {
      let existing = try await Current.db.query(AdminNotification.self)
        .where(.id == input.id)
        .where(.adminId == context.admin.id)
        .first()
      existing.methodId = input.methodId
      existing.trigger = input.trigger
      try await Current.db.update(existing)
      return .success
    } else {
      try await Current.db.create(AdminNotification(
        adminId: context.admin.id,
        methodId: input.methodId,
        trigger: input.trigger
      ))
      return .success
    }
  }
}

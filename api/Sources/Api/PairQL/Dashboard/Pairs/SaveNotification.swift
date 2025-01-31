import DuetSQL
import Foundation
import PairQL

struct SaveNotification: Pair {
  static let auth: ClientAuth = .admin

  struct Input: PairInput {
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
      var existing = try await AdminNotification.query()
        .where(.id == input.id)
        .where(.parentId == context.admin.id)
        .first(in: context.db)
      existing.methodId = input.methodId
      existing.trigger = input.trigger
      try await context.db.update(existing)
      return .success
    } else {
      try await context.db.create(AdminNotification(
        parentId: context.admin.id,
        methodId: input.methodId,
        trigger: input.trigger
      ))
      return .success
    }
  }
}

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
      var existing = try await Current.db.query(AdminNotification.self)
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

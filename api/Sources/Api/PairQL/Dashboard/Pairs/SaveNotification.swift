import DuetSQL
import Foundation
import PairQL

struct SaveNotification: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let id: Parent.Notification.Id
    let isNew: Bool
    let methodId: Parent.NotificationMethod.Id
    let trigger: Parent.Notification.Trigger
  }
}

// resolver

extension SaveNotification: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    if !input.isNew {
      var existing = try await Parent.Notification.query()
        .where(.id == input.id)
        .where(.parentId == context.parent.id)
        .first(in: context.db)
      existing.methodId = input.methodId
      existing.trigger = input.trigger
      try await context.db.update(existing)
      return .success
    } else {
      try await context.db.create(Parent.Notification(
        parentId: context.parent.id,
        methodId: input.methodId,
        trigger: input.trigger
      ))
      return .success
    }
  }
}

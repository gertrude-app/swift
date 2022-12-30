import DuetSQL
import Foundation
import TypescriptPairQL

struct SaveNotification_v0: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Input: TypescriptPairInput {
    let id: UUID?
    let methodId: UUID
    let trigger: AdminNotification.Trigger
  }

  struct Output: TypescriptPairOutput {
    let id: UUID
  }
}

// resolver

extension SaveNotification_v0: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    if let id = input.id {
      let existing = try await Current.db.query(AdminNotification.self)
        .where(.id == id)
        .where(.adminId == context.admin.id)
        .first()
      existing.methodId = .init(input.methodId)
      existing.trigger = input.trigger
      try await Current.db.update(existing)
      return .init(id: id)
    } else {
      let new = try await Current.db.create(AdminNotification(
        adminId: context.admin.id,
        methodId: .init(input.methodId),
        trigger: input.trigger
      ))
      return .init(id: new.id.rawValue)
    }
  }
}

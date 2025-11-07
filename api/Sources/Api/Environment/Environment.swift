import Dependencies
import DuetSQL
import Vapor
import XAws

struct VerificationCodeGenerator: Sendable {
  var generate: @Sendable () -> Int
}

extension Date {
  static let mock = Date(timeIntervalSinceReferenceDate: 0)
}

extension UUID {
  static let mock = UUID(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef")!
}

func unexpected(_ id: String, detail: String = "") {
  unexpected(id, nil, detail)
}

func unexpected(_ id: String, _ adminId: Parent.Id? = nil, _ detail: String = "") {
  Task { [detail] in
    with(dependency: \.logger).error("Unexpected event `\(id)`, \(detail)")
    with(dependency: \.postmark).unexpected(id, detail)
    try await with(dependency: \.db).create(InterestingEvent(
      eventId: id,
      kind: "event",
      context: "api",
      computerUserId: nil,
      parentId: adminId,
      detail: detail,
    ))
  }
}

func unexpected(_ id: String, _ context: some ResolverContext, _ detail: String = "") {
  var detail = detail
  let parentId: Parent.Id?
  if let parentContext = context as? ParentContext {
    parentId = parentContext.parent.id
    detail += ", parent id: \(parentId!.lowercased)"
  } else {
    parentId = nil
  }
  unexpected(id, parentId, detail)
}

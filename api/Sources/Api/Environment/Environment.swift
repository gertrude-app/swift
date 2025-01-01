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

func unexpected(_ id: String, _ adminId: Admin.Id? = nil, _ detail: String = "") {
  Task { [detail] in
    with(dependency: \.logger).error("Unexpected event `\(id)`, \(detail)")
    with(dependency: \.postmark).unexpected(id, detail)
    try await with(dependency: \.db).create(InterestingEvent(
      eventId: id,
      kind: "event",
      context: "api",
      userDeviceId: nil,
      adminId: adminId,
      detail: detail
    ))
  }
}

func unexpected(_ id: String, _ context: some ResolverContext, _ detail: String = "") {
  var detail = detail
  let adminId: Admin.Id?
  if let adminContext = context as? AdminContext {
    adminId = adminContext.admin.id
    detail += ", admin id: \(adminId!.lowercased)"
  } else {
    adminId = nil
  }
  unexpected(id, adminId, detail)
}

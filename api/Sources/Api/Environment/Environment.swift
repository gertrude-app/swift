import Dependencies
import DuetSQL
import Vapor
import XAws
import XPostmark
import XSendGrid

#if !DEBUG
  struct Environment: Sendable {
    let adminNotifier: AdminNotifier = .live
    let websockets: ConnectedApps = .live
    var logger: Logger = .null
  }
#else
  struct Environment: Sendable {
    var adminNotifier: AdminNotifier = .live
    var websockets: ConnectedApps = .live
    var logger: Logger = .null
  }
#endif

// SAFETY: in non-debug, the mutable members are only
// mutated synchronously during bootstrapping
// before the app starts serving requests
nonisolated(unsafe) var Current = Environment()

#if DEBUG
  extension Environment {
    static let mock = Environment(
      adminNotifier: .mock,
      websockets: .mock,
      logger: .null
    )
  }
#endif

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
  Current.logger.error("Unexpected event `\(id)`, \(detail)")
  with(dependency: \.sendgrid).fireAndForget(.unexpected(id, detail))
  Task { [detail] in
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

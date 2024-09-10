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
    let ephemeral: Ephemeral = .init()
    var logger: Logger = .null
    var postmark: XPostmark.Client = .mock
    var sendGrid: SendGrid.Client = .mock
  }
#else
  struct Environment: Sendable {
    var adminNotifier: AdminNotifier = .live
    var websockets: ConnectedApps = .live
    var ephemeral: Ephemeral = .init()
    var logger: Logger = .null
    var postmark: XPostmark.Client = .mock
    var sendGrid: SendGrid.Client = .mock
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
      ephemeral: .init(),
      logger: .null,
      postmark: .mock,
      sendGrid: .mock
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
  Current.sendGrid.fireAndForget(.unexpected(id, detail))
  Task { [detail] in
    @Dependency(\.db) var db
    try await db.create(InterestingEvent(
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

import PairQL
import Vapor

struct LogEvent: Pair {
  static let auth: ClientAuth = .admin

  struct Input: PairInput {
    var eventId: String
    var detail: String
  }
}

// resolver

extension LogEvent: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    if isTestAddress(context.admin.email.rawValue) {
      return .success
    }
    try await InterestingEvent(
      eventId: input.eventId,
      kind: "event",
      context: "dash",
      userDeviceId: nil,
      adminId: context.admin.id,
      detail: input.detail
    ).create()
    let msg = "Dash interesting event: \(input.eventId)  \(input.detail)"
    await Current.slack.sysLog(msg)
    return .success
  }
}

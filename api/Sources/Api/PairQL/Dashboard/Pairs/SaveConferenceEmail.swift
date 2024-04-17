import PairQL
import Vapor

struct SaveConferenceEmail: Pair {
  static var auth: ClientAuth = .none

  struct Input: PairInput {
    enum Source: String, Codable {
      case workshop
      case booth
    }

    var email: String
    var source: Source
  }
}

// resolver

extension SaveConferenceEmail: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let detail = "SaveConferenceEmail: \(input.email), source: \(input.source)"
    _ = try? await InterestingEvent.create(.init(
      eventId: "cc29a271",
      kind: "event",
      context: "marketing",
      userDeviceId: nil,
      adminId: nil,
      detail: detail
    ))

    await Current.slack.sysLog(detail)
    return .success
  }
}

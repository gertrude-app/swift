import PairQL
import Vapor

struct SaveConferenceEmail: Pair {
  static let auth: ClientAuth = .none

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
    _ = try? await context.db.create(InterestingEvent(
      eventId: "cc29a271",
      kind: "event",
      context: "marketing",
      computerUserId: nil,
      parentId: nil,
      detail: detail,
    ))

    await with(dependency: \.slack).internal(.info, detail)
    return .success
  }
}

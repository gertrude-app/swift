import Gertie
import PairQL

struct DecideFilterSuspensionRequest: Pair {
  static let auth: ClientAuth = .admin

  enum Decision: PairNestable {
    case rejected
    case accepted(durationInSeconds: Int, extraMonitoring: String?)
  }

  struct Input: PairInput {
    var id: SuspendFilterRequest.Id
    var decision: Decision
    var responseComment: String?
  }
}

// resolver

extension DecideFilterSuspensionRequest: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    var suspendFilterRequest = try await SuspendFilterRequest.find(input.id)
    let userDevice = try await suspendFilterRequest.userDevice()
    try await context.verifiedUser(from: userDevice.userId)

    suspendFilterRequest.responseComment = input.responseComment
    let decision = input.decision.filterSuspensionDecision

    switch decision {
    case .accepted(let duration, let extraMonitoring):
      suspendFilterRequest.duration = duration
      suspendFilterRequest.status = .accepted
      suspendFilterRequest.extraMonitoring = extraMonitoring?.magicString
    case .rejected:
      suspendFilterRequest.status = .rejected
    }

    try await suspendFilterRequest.save()

    try await Current.websockets.send(
      suspendFilterRequest.updated(for: userDevice.appSemver),
      to: .userDevice(userDevice.id)
    )

    return .success
  }
}

// extensions

extension SuspendFilterRequest {
  func updated(for version: Semver) -> WebSocketMessage.FromApiToApp {
    switch self.status {
    case .accepted where version < .init("2.1.0")!:
      .suspendFilter(for: self.duration, parentComment: self.responseComment)
    case _ where version < .init("2.1.0")!:
      .suspendFilterRequestDenied(parentComment: self.responseComment)
    case _ where version < .init("2.4.0")!:
      .filterSuspensionRequestDecided(
        decision: self.decision ?? .rejected,
        comment: self.responseComment
      )
    default:
      .filterSuspensionRequestDecided_v2(
        id: self.id.rawValue,
        decision: self.decision ?? .rejected,
        comment: self.responseComment
      )
    }
  }
}

extension DecideFilterSuspensionRequest.Decision {
  var filterSuspensionDecision: FilterSuspensionDecision {
    switch self {
    case .rejected:
      return .rejected
    case .accepted(let durationInSeconds, let magicString):
      return .accepted(
        duration: .init(durationInSeconds),
        extraMonitoring: magicString
          .flatMap(FilterSuspensionDecision.ExtraMonitoring.init(magicString:))
      )
    }
  }
}

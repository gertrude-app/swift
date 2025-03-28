import Gertie
import PairQL

struct DecideFilterSuspensionRequest: Pair {
  static let auth: ClientAuth = .parent

  enum Decision: PairNestable {
    case rejected
    case accepted(durationInSeconds: Int, extraMonitoring: String?)
  }

  struct Input: PairInput {
    var id: MacApp.SuspendFilterRequest.Id
    var decision: Decision
    var responseComment: String?
  }
}

// resolver

extension DecideFilterSuspensionRequest: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    var suspendFilterRequest = try await context.db.find(input.id)
    let userDevice = try await suspendFilterRequest.userDevice(in: context.db)
    try await context.verifiedUser(from: userDevice.childId)

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

    try await context.db.update(suspendFilterRequest)

    try await with(dependency: \.websockets).send(
      .filterSuspensionRequestDecided_v2(
        id: suspendFilterRequest.id.rawValue,
        decision: suspendFilterRequest.decision ?? .rejected,
        comment: suspendFilterRequest.responseComment
      ),
      to: .userDevice(userDevice.id)
    )

    return .success
  }
}

// extensions

extension DecideFilterSuspensionRequest.Decision {
  var filterSuspensionDecision: FilterSuspensionDecision {
    switch self {
    case .rejected:
      .rejected
    case .accepted(let durationInSeconds, let magicString):
      .accepted(
        duration: .init(durationInSeconds),
        extraMonitoring: magicString
          .flatMap(FilterSuspensionDecision.ExtraMonitoring.init(magicString:))
      )
    }
  }
}

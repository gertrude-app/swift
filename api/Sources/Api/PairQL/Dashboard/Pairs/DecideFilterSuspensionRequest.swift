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
    var request = try await Current.db.find(input.id)
    let userDevice = try await request.userDevice()
    try await context.verifiedUser(from: userDevice.userId)

    request.responseComment = input.responseComment
    let decision = input.decision.filterSuspensionDecision

    switch decision {
    case .accepted(let duration, _):
      request.duration = duration
      request.status = .accepted
    case .rejected:
      request.status = .rejected
    }

    try await request.save()

    if Semver(userDevice.appVersion)! >= .init("2.1.0")! {
      try await Current.connectedApps.notify(.suspendFilterRequestDecided(
        userDevice.id,
        decision,
        input.responseComment
      ))
    } else {
      try await Current.connectedApps.notify(.suspendFilterRequestUpdated(.init(
        userDeviceId: userDevice.id,
        status: request.status,
        duration: request.duration,
        requestComment: request.requestComment,
        responseComment: request.responseComment
      )))
    }

    return .success
  }
}

// extensions

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

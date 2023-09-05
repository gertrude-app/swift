import Gertie
import PairQL

struct DecideFilterSuspensionRequest: Pair {
  static var auth: ClientAuth = .admin

  struct Input: PairInput {
    var id: SuspendFilterRequest.Id
    var decision: FilterSuspensionDecision
    var responseComment: String?
  }
}

// resolver

extension DecideFilterSuspensionRequest: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    let request = try await Current.db.find(input.id)
    let userDevice = try await request.userDevice()
    try await context.verifiedUser(from: userDevice.userId)

    switch input.decision {
    case .accepted(let durationInSeconds, _):
      request.duration = .init(durationInSeconds)
      request.responseComment = input.responseComment
      request.status = .accepted
    case .rejected:
      request.responseComment = input.responseComment
      request.status = .rejected
    }

    try await request.save()

    if Semver(userDevice.appVersion)! >= .init("2.1.0")! {
      try await Current.connectedApps
        .notify(.suspendFilterRequestDecided(userDevice.id, input.decision))
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

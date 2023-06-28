import PairQL
import Shared

struct UpdateSuspendFilterRequest: Pair {
  static var auth: ClientAuth = .admin

  struct Input: PairInput {
    let id: SuspendFilterRequest.Id
    let durationInSeconds: Int
    let responseComment: String?
    let status: RequestStatus
  }
}

// resolver

extension UpdateSuspendFilterRequest: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    let request = try await Current.db.find(input.id)
    let device = try await request.device()
    try await context.verifiedUser(from: device.userId)
    request.duration = .init(input.durationInSeconds)
    request.responseComment = input.responseComment
    request.status = input.status
    try await Current.db.update(request)

    try await Current.connectedApps.notify(.suspendFilterRequestUpdated(.init(
      deviceId: device.id,
      status: request.status,
      duration: request.duration,
      requestComment: request.requestComment,
      responseComment: request.responseComment
    )))

    return .success
  }
}

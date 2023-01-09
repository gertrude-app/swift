import MacAppRoute
import Vapor

extension CreateSuspendFilterRequest: Resolver {
  static func resolve(
    with input: Input,
    in context: UserContext
  ) async throws -> Output {
    guard let device = try await context.token.device() else {
      throw Abort(.notFound, reason: "missing device")
    }

    try await Current.db.create(SuspendFilterRequest(
      deviceId: device.id,
      status: .pending,
      scope: .unrestricted,
      duration: .init(rawValue: input.duration),
      requestComment: input.comment
    ))

    // TODO: event, notify connected eapp
    // let payload = Event.Payload.SuspendFilterRequestSubmitted(
    //   adminId: user.adminId,
    //   deviceId: device.id,
    //   userName: user.name,
    //   duration: .init(rawValue: args.duration),
    //   requestId: suspendRequest.id,
    //   requestComment: args.requestComment
    // )
    // try await Current.events.receive(.suspendFilterRequestSubmitted(payload))

    return .success
  }
}

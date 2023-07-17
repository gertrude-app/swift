import Foundation
import Gertie
import PairQL

struct GetSuspendFilterRequest: Pair {
  static var auth: ClientAuth = .admin
  typealias Input = SuspendFilterRequest.Id

  struct Output: PairOutput {
    let id: Api.SuspendFilterRequest.Id
    let deviceId: Api.UserDevice.Id
    let status: RequestStatus
    let userName: String
    let requestedDurationInSeconds: Int
    let requestComment: String?
    let responseComment: String?
    let createdAt: Date
  }
}

// resolver

extension GetSuspendFilterRequest: Resolver {
  static func resolve(with id: Input, in context: AdminContext) async throws -> Output {
    let request = try await Current.db.find(id)
    let userDevice = try await request.userDevice()
    let user = try await userDevice.user()
    return Output(
      id: id,
      deviceId: userDevice.id,
      status: request.status,
      userName: user.name,
      requestedDurationInSeconds: request.duration.rawValue,
      requestComment: request.requestComment,
      responseComment: request.responseComment,
      createdAt: request.createdAt
    )
  }
}

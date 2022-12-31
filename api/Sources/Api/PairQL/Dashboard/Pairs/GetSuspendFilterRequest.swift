import Foundation
import Shared
import TypescriptPairQL

struct GetSuspendFilterRequest: TypescriptPair {
  static var auth: ClientAuth = .admin
  typealias Input = SuspendFilterRequest.Id

  struct Output: TypescriptPairOutput {
    let id: SuspendFilterRequest.Id
    let deviceId: Device.Id
    let userName: String
    let requestedDurationInSeconds: Int
    let requestComment: String?
    let status: RequestStatus
    let createdAt: Date
  }
}

// resolver

extension GetSuspendFilterRequest: Resolver {
  static func resolve(with id: Input, in context: AdminContext) async throws -> Output {
    let request = try await Current.db.find(id)
    let device = try await request.device()
    let user = try await device.user()
    return Output(
      id: id,
      deviceId: device.id,
      userName: user.name,
      requestedDurationInSeconds: request.duration.rawValue,
      requestComment: request.requestComment,
      status: request.status,
      createdAt: request.createdAt
    )
  }
}

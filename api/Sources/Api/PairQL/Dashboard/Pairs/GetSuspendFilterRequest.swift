import Foundation
import Shared
import TypescriptPairQL

struct GetSuspendFilterRequest: TypescriptPair {
  static var auth: ClientAuth = .admin
  typealias Input = SuspendFilterRequest.Id

  struct Output: TypescriptPairOutput, GlobalType {
    let id: Api.SuspendFilterRequest.Id
    let deviceId: Api.Device.Id
    let status: RequestStatus
    let userName: String
    let requestedDurationInSeconds: Int
    let requestComment: String?
    let responseComment: String?
    let createdAt: Date

    static var __typeName: String {
      "SuspendFilterRequest"
    }
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
      status: request.status,
      userName: user.name,
      requestedDurationInSeconds: request.duration.rawValue,
      requestComment: request.requestComment,
      responseComment: request.responseComment,
      createdAt: request.createdAt
    )
  }
}
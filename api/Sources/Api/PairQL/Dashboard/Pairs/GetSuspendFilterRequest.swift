import Foundation
import Gertie
import PairQL

struct GetSuspendFilterRequest: Pair {
  static var auth: ClientAuth = .admin
  typealias Input = SuspendFilterRequest.Id

  struct Output: PairOutput {
    var id: Api.SuspendFilterRequest.Id
    var deviceId: Api.UserDevice.Id
    var status: RequestStatus
    var userName: String
    var requestedDurationInSeconds: Int
    var requestComment: String?
    var responseComment: String?
    var canDoubleScreenshots: Bool
    var createdAt: Date
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
      canDoubleScreenshots: Semver(userDevice.appVersion)! >= .init("2.1.0")!
        && user.screenshotsEnabled,
      createdAt: request.createdAt
    )
  }
}

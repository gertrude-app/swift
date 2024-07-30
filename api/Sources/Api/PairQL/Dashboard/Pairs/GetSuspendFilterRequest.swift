import Foundation
import Gertie
import PairQL

struct GetSuspendFilterRequest: Pair {
  static let auth: ClientAuth = .admin
  typealias Input = SuspendFilterRequest.Id

  struct Output: PairOutput {
    var id: Api.SuspendFilterRequest.Id
    var deviceId: Api.UserDevice.Id
    var status: RequestStatus
    var userName: String
    var requestedDurationInSeconds: Int
    var requestComment: String?
    var responseComment: String?
    var extraMonitoringOptions: [String: String]
    var createdAt: Date
  }
}

// resolver

extension GetSuspendFilterRequest: Resolver {
  static func resolve(with id: Input, in context: AdminContext) async throws -> Output {
    let request = try await Current.db.find(id)
    let userDevice = try await request.userDevice()
    let user = try await userDevice.user()
    var extraMonitoringOptions: [String: String] = [:]
    if Semver(userDevice.appVersion)! >= .init("2.1.0")! {
      extraMonitoringOptions = user.extraMonitoringOptions.mapKeys(\.magicString)
    }
    return Output(
      id: id,
      deviceId: userDevice.id,
      status: request.status,
      userName: user.name,
      requestedDurationInSeconds: request.duration.rawValue,
      requestComment: request.requestComment,
      responseComment: request.responseComment,
      extraMonitoringOptions: extraMonitoringOptions,
      createdAt: request.createdAt
    )
  }
}

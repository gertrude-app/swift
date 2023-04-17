import Foundation
import PairQL
import Shared

struct GetUnlockRequest: Pair {
  static var auth: ClientAuth = .admin

  struct Output: PairOutput {
    let id: Api.UnlockRequest.Id
    let userId: Api.User.Id
    let userName: String
    let status: RequestStatus
    let url: String?
    let domain: String?
    let ipAddress: String?
    let requestComment: String?
    let appName: String?
    let appSlug: String?
    let appBundleId: String?
    let appCategories: [String]
    let requestProtocol: String?
    let createdAt: Date
  }

  typealias Input = UnlockRequest.Id
}

// resolver

extension GetUnlockRequest: Resolver {
  static func resolve(with id: Input, in context: AdminContext) async throws -> Output {
    let request = try await Current.db.find(id)
    return try await Output(from: request, in: context)
  }
}

extension GetUnlockRequest.Output {
  init(from request: UnlockRequest, in context: AdminContext) async throws {
    let device = try await request.device()
    let decision = try await request.networkDecision()
    let user = try await context.verifiedUser(from: device.userId)

    var app: AppDescriptor?
    if let bundleId = decision.appBundleId {
      let idManifest = try await getCachedAppIdManifest()
      let factory = AppDescriptorFactory(appIdManifest: idManifest)
      app = factory.appDescriptor(for: bundleId)
    }

    self.init(
      id: request.id,
      userId: user.id,
      userName: user.name,
      status: request.status,
      url: decision.url,
      domain: decision.hostname,
      ipAddress: decision.ipAddress,
      requestComment: request.requestComment,
      appName: app?.displayName,
      appSlug: app?.slug,
      appBundleId: decision.appBundleId,
      appCategories: Array(app?.categories ?? []),
      requestProtocol: decision.ipProtocol?.description,
      createdAt: request.createdAt
    )
  }
}

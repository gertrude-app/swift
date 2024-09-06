import Foundation
import Gertie
import PairQL

struct GetUnlockRequest: Pair {
  static let auth: ClientAuth = .admin

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
    let createdAt: Date
  }

  typealias Input = UnlockRequest.Id
}

// resolver

extension GetUnlockRequest: Resolver {
  static func resolve(with id: Input, in context: AdminContext) async throws -> Output {
    let request = try await UnlockRequest.find(id)
    return try await Output(from: request, in: context)
  }
}

extension GetUnlockRequest.Output {
  init(from request: UnlockRequest, in context: AdminContext) async throws {
    let userDevice = try await request.userDevice()
    let user = try await context.verifiedUser(from: userDevice.userId)

    let idManifest = try await getCachedAppIdManifest()
    let factory = AppDescriptorFactory(appIdManifest: idManifest)
    let app = factory.appDescriptor(for: request.appBundleId)

    self.init(
      id: request.id,
      userId: user.id,
      userName: user.name,
      status: request.status,
      url: request.url,
      domain: request.hostname,
      ipAddress: request.ipAddress,
      requestComment: request.requestComment,
      appName: app.displayName,
      appSlug: app.slug,
      appBundleId: request.appBundleId,
      appCategories: Array(app.categories),
      createdAt: request.createdAt
    )
  }
}

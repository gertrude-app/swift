import DuetSQL
import Gertie
import MacAppRoute

extension CheckIn: Resolver {
  static func resolve(with input: Input, in context: UserContext) async throws -> Output {
    async let v1 = RefreshRules.resolve(with: .init(appVersion: input.appVersion), in: context)
    async let admin = context.user.admin(in: context.db)
    async let browsers = Browser.query().all(in: context.db)
    var userDevice = try await context.userDevice()
    var adminDevice = try await userDevice.adminDevice(in: context.db)
    let channel = adminDevice.appReleaseChannel

    async let latestRelease = LatestAppVersion.resolve(
      with: .init(releaseChannel: channel, currentVersion: input.appVersion),
      in: .init(
        requestId: context.requestId,
        dashboardUrl: context.dashboardUrl,
        ipAddress: nil
      )
    )

    if let filterVersionSemver = input.filterVersion,
       let filterVersion = Semver(filterVersionSemver),
       filterVersion != adminDevice.filterVersion {
      adminDevice.filterVersion = filterVersion
      try await context.db.update(adminDevice)
    }

    if let osVersionSemver = input.osVersion,
       let osVersion = Semver(osVersionSemver),
       osVersion != adminDevice.osVersion {
      adminDevice.osVersion = osVersion
      try await context.db.update(adminDevice)
    }

    if let userIsAdmin = input.userIsAdmin,
       userDevice.isAdmin != userIsAdmin {
      userDevice.isAdmin = userIsAdmin
      try await context.db.update(userDevice)
    }

    var resolvedFilterSuspension: ResolvedFilterSuspension?
    if let suspensionReqId = input.pendingFilterSuspension,
       let resolved = try? await SuspendFilterRequest.query()
       .where(.id == suspensionReqId)
       .where(.userDeviceId == userDevice.id)
       .where(.status != .enum(RequestStatus.pending))
       .first(in: context.db) {
      resolvedFilterSuspension = .init(
        id: resolved.id.rawValue,
        decision: resolved.decision ?? .rejected,
        comment: resolved.responseComment
      )
    }

    var resolvedUnlockRequests: [ResolvedUnlockRequest]?
    if let unlockIds = input.pendingUnlockRequests,
       !unlockIds.isEmpty {
      let resolved = try await UnlockRequest.query()
        .where(.id |=| unlockIds)
        .where(.userDeviceId == userDevice.id)
        .where(.status != .enum(RequestStatus.pending))
        .all(in: context.db)
      if !resolved.isEmpty {
        resolvedUnlockRequests = resolved.map { .init(
          id: $0.id.rawValue,
          status: $0.status,
          target: $0.target ?? "",
          comment: $0.responseComment
        ) }
      }
    }

    return Output(
      adminAccountStatus: try await admin.accountStatus,
      appManifest: try await v1.appManifest,
      keys: try await v1.keys,
      latestRelease: try await latestRelease,
      updateReleaseChannel: channel,
      userData: .init(
        id: context.user.id.rawValue,
        token: context.token.value.rawValue,
        deviceId: userDevice.id.rawValue,
        name: context.user.name,
        keyloggingEnabled: context.user.keyloggingEnabled,
        screenshotsEnabled: context.user.screenshotsEnabled,
        screenshotFrequency: context.user.screenshotsFrequency,
        screenshotSize: context.user.screenshotsResolution,
        connectedAt: userDevice.createdAt
      ),
      browsers: try await browsers.map(\.match),
      resolvedFilterSuspension: resolvedFilterSuspension,
      resolvedUnlockRequests: resolvedUnlockRequests,
      trustedTime: get(dependency: \.date.now).timeIntervalSince1970
    )
  }
}

import DuetSQL
import Gertie
import MacAppRoute

extension CheckIn: Resolver {
  static func resolve(with input: Input, in context: UserContext) async throws -> Output {
    async let appManifest = getCachedAppIdManifest()
    async let admin = context.user.admin(in: context.db)
    async let browsers = Browser.query().all(in: context.db)

    let keychains = try await context.user.keychains(in: context.db)
    var keys = try await keychains.concurrentMap { keychain in
      try await keychain.keys(in: context.db)
    }.flatMap { $0 }

    // update the app version if it changed
    var userDevice = try await context.userDevice()
    if !input.appVersion.isEmpty, input.appVersion != userDevice.appVersion {
      userDevice.appVersion = input.appVersion
      try await context.db.update(userDevice)
    }

    // merge in the AUTO-INCLUDED Keychain
    if !keys.isEmpty {
      let autoId = context.env.get("AUTO_INCLUDED_KEYCHAIN_ID")
        .flatMap(UUID.init(uuidString:)) ?? context.uuid()
      let autoKeychain = try? await context.db.find(Keychain.Id(autoId))
      if let autoKeychain = autoKeychain {
        let autoKeys = try await autoKeychain.keys(in: context.db)
        keys.append(contentsOf: autoKeys)
      }
    }

    var adminDevice = try await userDevice.adminDevice(in: context.db)
    let channel = adminDevice.appReleaseChannel

    async let latestRelease = resolveLatestRelease(
      channel: channel,
      currentAppVersion: input.appVersion,
      db: context.db
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
      appManifest: try await appManifest,
      keys: keys.map { .init(id: $0.id.rawValue, key: $0.key) },
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

func resolveLatestRelease(
  channel: ReleaseChannel,
  currentAppVersion: String,
  db: any Client
) async throws -> CheckIn.LatestRelease {
  let releases = try await Release.query()
    .orderBy(.semver, .asc)
    .all(in: db)

  let currentSemver = Semver(currentAppVersion)!
  var latest = CheckIn.LatestRelease(semver: currentSemver.string)

  for release in releases {
    if currentSemver.isBehind(release),
       release.channel.isAtLeastAsStable(as: channel) {
      latest.semver = release.semver
      if let pace = release.requirementPace, latest.pace == nil {
        latest.pace = .init(
          nagOn: release.createdAt.advanced(by: .days(pace)),
          requireOn: release.createdAt.advanced(by: .days(pace * 2))
        )
      }
    }
  }

  return latest
}

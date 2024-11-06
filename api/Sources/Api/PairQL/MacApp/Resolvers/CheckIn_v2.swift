import DuetSQL
import Gertie
import MacAppRoute

extension CheckIn_v2: Resolver {
  static func resolve(with input: Input, in context: UserContext) async throws -> Output {
    async let appManifest = getCachedAppIdManifest()
    async let admin = context.user.admin(in: context.db)
    async let browsers = Browser.query().all(in: context.db)
    var keychains = try await ruleKeychains(for: context.user.id, in: context.db)

    // merge in the AUTO-INCLUDED Keychain
    if !keychains.isEmpty, keychains.allSatisfy(\.keys.isEmpty) == false {
      let autoId = context.env.get("AUTO_INCLUDED_KEYCHAIN_ID")
        .flatMap(UUID.init(uuidString:)) ?? context.uuid()
      let autoKeychain = try? await context.db.find(Keychain.Id(autoId))
      if let autoKeychain {
        let autoKeys = try await autoKeychain.keys(in: context.db)
        keychains.append(.init(
          id: autoId,
          keys: autoKeys.map { .init(id: $0.id.rawValue, key: $0.key) }
        ))
      }
    }

    // update the app version if it changed
    var userDevice = try await context.userDevice()
    if !input.appVersion.isEmpty, input.appVersion != userDevice.appVersion {
      userDevice.appVersion = input.appVersion
      try await context.db.update(userDevice)
    }

    var adminDevice = try await userDevice.adminDevice(in: context.db)
    let channel = adminDevice.appReleaseChannel

    async let latestRelease = resolveLatestRelease(
      channel: channel,
      currentAppVersion: input.appVersion,
      in: context.db
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

    var resolvedFilterSuspension: CheckIn_v2.ResolvedFilterSuspension?
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

    var resolvedUnlockRequests: [CheckIn_v2.ResolvedUnlockRequest]?
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
      keychains: keychains,
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

// helpers

// TODO: this is major N+1 territory, write a custom query w/ join for perf
// @see also userKeychainSummaries(for:in:)
func ruleKeychains(
  for userId: User.Id,
  in db: any DuetSQL.Client
) async throws -> [RuleKeychain] {
  let userKeychains = try await UserKeychain.query()
    .where(.userId == userId)
    .all(in: db)
  let keychains = try await Keychain.query()
    .where(.id |=| userKeychains.map(\.keychainId))
    .all(in: db)
  return try await keychains.concurrentMap { keychain in
    let keys = try await keychain.keys(in: db)
    return .init(
      id: keychain.id.rawValue,
      schedule: userKeychains.first { $0.keychainId == keychain.id }?.schedule,
      keys: keys.map { .init(id: $0.id.rawValue, key: $0.key) }
    )
  }
}

func resolveLatestRelease(
  channel: ReleaseChannel,
  currentAppVersion: String,
  in db: any Client
) async throws -> CheckIn_v2.LatestRelease {
  let releases = try await Release.query()
    .orderBy(.semver, .asc)
    .all(in: db)

  let currentSemver = Semver(currentAppVersion)!
  var latest = CheckIn_v2.LatestRelease(semver: currentSemver.string)

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

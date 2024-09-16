import DuetSQL
import MacAppRoute

extension RefreshRules: Resolver {
  static func resolve(with input: Input, in context: UserContext) async throws -> Output {
    let user = context.user
    let keychains = try await user.keychains(in: context.db)
    var keys = try await keychains.concurrentMap { keychain in
      try await keychain.keys(in: context.db)
    }.flatMap { $0 }

    // update the app version if it changed
    if var userDevice = try? await context.userDevice(),
       !input.appVersion.isEmpty,
       input.appVersion != userDevice.appVersion {
      userDevice.appVersion = input.appVersion
      try await context.db.update(userDevice)
    }

    // ...merging in AUTO-INCLUDED Keychain
    if !keys.isEmpty {
      let autoId = context.env.get("AUTO_INCLUDED_KEYCHAIN_ID")
        .flatMap(UUID.init(uuidString:)) ?? context.uuid()
      let autoKeychain = try? await context.db.find(Keychain.Id(autoId))
      if let autoKeychain = autoKeychain {
        let autoKeys = try await autoKeychain.keys(in: context.db)
        keys.append(contentsOf: autoKeys)
      }
    }

    return Output(
      appManifest: try await getCachedAppIdManifest(),
      keyloggingEnabled: user.keyloggingEnabled,
      screenshotsEnabled: user.screenshotsEnabled,
      screenshotsFrequency: user.screenshotsFrequency,
      screenshotsResolution: user.screenshotsResolution,
      keys: keys.map { key in
        .init(id: key.id.rawValue, key: key.key)
      }
    )
  }
}

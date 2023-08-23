import DuetSQL
import MacAppRoute

extension RefreshRules: Resolver {
  static func resolve(with input: Input, in context: UserContext) async throws -> Output {
    let user = context.user
    let keychains = try await user.keychains()
    var keys = try await keychains.concurrentMap { keychain in
      try await keychain.keys()
    }.flatMap { $0 }

    // update the app version if it changed
    if let userDevice = try? await context.userDevice(),
       !input.appVersion.isEmpty,
       input.appVersion != userDevice.appVersion {
      userDevice.appVersion = input.appVersion
      try await Current.db.update(userDevice)
    }

    // ...merging in AUTO-INCLUDED Keychain
    if !keys.isEmpty {
      let autoKeychain = try await Current.db.query(Keychain.self)
        .where(.name == "__auto_included__")
        .orderBy(.createdAt, .desc) // safeguard against dupes
        .limit(1)
        .all()
        .first
      if let autoKeychain = autoKeychain {
        let autoKeys = try await autoKeychain.keys()
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

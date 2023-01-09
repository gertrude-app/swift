import MacAppRoute

extension RefreshRules: NoInputResolver {
  static func resolve(in context: UserContext) async throws -> Output {
    let user = context.user
    let keychains = try await user.keychains()
    let keys = try await keychains.concurrentMap { keychain in
      try await keychain.keys()
    }.flatMap { $0 }

    return Output(
      appManifest: try await getCachedAppIdManifest(),
      keyloggingEnabled: user.keyloggingEnabled,
      screenshotsEnabled: user.screenshotsEnabled,
      screenshotsFrequency: user.screenshotsFrequency,
      screenshotsResolution: user.screenshotsResolution,
      keys: keys.map { key in
        Key(id: key.id.rawValue, key: key.key)
      }
    )
  }
}

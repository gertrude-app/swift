import MacAppRoute

#if DEBUG

  extension RefreshRules.Output {
    static let mock = Self(
      appManifest: .init(),
      keyloggingEnabled: true,
      screenshotsEnabled: true,
      screenshotsFrequency: 333,
      screenshotsResolution: 555,
      keys: []
    )
  }

#endif

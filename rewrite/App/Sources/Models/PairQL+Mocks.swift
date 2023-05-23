import MacAppRoute

extension RefreshRules.Output {
  static let mock = Self(
    appManifest: .init(),
    keyloggingEnabled: true,
    screenshotsEnabled: true,
    screenshotsFrequency: 333,
    screenshotsResolution: 555,
    keys: []
  )

  static func mock(configure: (inout Self) -> Void) -> Self {
    var mock = Self.mock
    configure(&mock)
    return mock
  }
}

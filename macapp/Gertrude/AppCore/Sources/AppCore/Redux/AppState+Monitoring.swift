import XCore

// tried changing this to a struct, but had whacky problems on initial launch :/
class MonitoringState: Equatable, Codable {
  var keyloggingEnabled: Bool
  var screenshotsEnabled: Bool
  var screenshotFrequency: Int
  var screenshotSize: Int

  init(
    keyloggingEnabled: Bool = Current.deviceStorage.getBool(.keyloggingEnabled) ?? false,
    screenshotsEnabled: Bool = Current.deviceStorage.getBool(.screenshotsEnabled) ?? false,
    screenshotFrequency: Int = Current.deviceStorage.getInt(.screenshotFrequency) ?? 180,
    screenshotSize: Int = Current.deviceStorage.getInt(.screenshotSize) ?? 1000
  ) {
    self.keyloggingEnabled = keyloggingEnabled
    self.screenshotsEnabled = screenshotsEnabled
    self.screenshotFrequency = screenshotFrequency
    self.screenshotSize = screenshotSize
  }

  static func == (lhs: MonitoringState, rhs: MonitoringState) -> Bool {
    (try? JSON.encode(lhs)) == (try? JSON.encode(rhs))
  }
}

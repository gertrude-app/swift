import TaggedTime

public enum FilterSuspensionDecision: Codable, Equatable, Sendable {
  case rejected
  case accepted(duration: Seconds<Int>, extraMonitoring: ExtraMonitoring?)

  public enum ExtraMonitoring: Sendable, Codable, Equatable, Hashable {
    case addKeylogging
    case setScreenshotFreq(Int)
    case addKeyloggingAndSetScreenshotFreq(Int)
  }
}

public extension FilterSuspensionDecision {
  var requestStatus: RequestStatus {
    switch self {
    case .rejected:
      return .rejected
    case .accepted:
      return .accepted
    }
  }
}

public extension FilterSuspensionDecision.ExtraMonitoring {
  var screenshotsFrequency: Int? {
    switch self {
    case .addKeylogging:
      return nil
    case .setScreenshotFreq(let frequency), .addKeyloggingAndSetScreenshotFreq(let frequency):
      return frequency
    }
  }

  var addsKeylogging: Bool {
    switch self {
    case .addKeylogging, .addKeyloggingAndSetScreenshotFreq:
      return true
    case .setScreenshotFreq:
      return false
    }
  }
}

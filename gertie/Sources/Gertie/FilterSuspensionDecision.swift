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
      .rejected
    case .accepted:
      .accepted
    }
  }
}

public extension FilterSuspensionDecision.ExtraMonitoring {
  var screenshotsFrequency: Int? {
    switch self {
    case .addKeylogging:
      nil
    case .setScreenshotFreq(let frequency), .addKeyloggingAndSetScreenshotFreq(let frequency):
      frequency
    }
  }

  var setsScreenshotFrequency: Bool {
    switch self {
    case .addKeylogging:
      false
    case .setScreenshotFreq, .addKeyloggingAndSetScreenshotFreq:
      true
    }
  }

  var addsKeylogging: Bool {
    switch self {
    case .addKeylogging, .addKeyloggingAndSetScreenshotFreq:
      true
    case .setScreenshotFreq:
      false
    }
  }
}

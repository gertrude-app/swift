public enum FilterSuspensionDecision: Codable, Equatable, Sendable {
  case rejected
  case accepted(durationInSeconds: Int, doubledScreenshots: DoubledScreenshots?)

  public enum DoubledScreenshots: String, Codable, Sendable {
    case enabled
    case enabledInformingUser
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

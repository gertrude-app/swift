// the real low-level system extension filter status
public enum FilterStatus: String, Codable {
  case error
  case unknown
  case notInstalled
  case installedButNotRunning
  case installedAndRunning
}

// filter "state" -- a higher-level, user-facing view of the filter
// including the possibility that it is "suspended" temporarily
public enum FilterState: String, Codable, CaseIterable, Equatable {
  case on
  case off
  case suspended
}

// NB: when macapp rewrite complete, this should be deleted

// filter "state" -- a higher-level, user-facing view of the filter
// including the possibility that it is "suspended" temporarily
public enum FilterState: String, Codable, CaseIterable, Equatable {
  case on
  case off
  case suspended
}

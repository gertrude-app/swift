// the simplified app-perspective of the filter, what the user/admin
// would usually want to know, omitting low-level extension details
public enum UserFilterState: String, Codable, CaseIterable, Equatable, Sendable {
  case on
  case off
  case suspended
}

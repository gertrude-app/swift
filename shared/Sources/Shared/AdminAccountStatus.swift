public enum AdminAccountStatus: String, Codable, Equatable, CaseIterable, Sendable {
  case active
  case needsAttention
  case inactive
}

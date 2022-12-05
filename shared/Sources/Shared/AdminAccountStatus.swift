public enum AdminAccountStatus: String, Codable, Equatable, CaseIterable {
  case active
  case needsAttention
  case inactive
}

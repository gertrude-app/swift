public enum FlowType {
  case browser
  case socket
}

// conformances

extension FlowType: Equatable, Codable, Sendable, Hashable {}

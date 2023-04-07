public enum RequestStatus: String, Codable, CaseIterable, Equatable, Sendable {
  case pending
  case accepted
  case rejected
}

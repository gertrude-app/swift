public enum ReleaseChannel: String, Codable, Equatable, CaseIterable, Sendable {
  case stable
  case beta
  case canary
}

public extension ReleaseChannel {
  func isMoreStable(than other: ReleaseChannel) -> Bool {
    switch (self, other) {
    case (.stable, .stable), (.canary, .canary), (.beta, .beta):
      false
    case (.stable, .beta), (.stable, .canary), (.beta, .canary):
      true
    case (.beta, .stable), (.canary, _):
      false
    }
  }

  func isAtLeastAsStable(as other: ReleaseChannel) -> Bool {
    self == other || self.isMoreStable(than: other)
  }
}

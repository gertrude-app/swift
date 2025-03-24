public enum BrowserMatch: Equatable, Sendable, Codable {
  case bundleId(String)
  case name(String)
}

public extension BrowserMatch {
  var name: String? {
    switch self {
    case .name(let name):
      name
    default:
      nil
    }
  }

  var bundleId: String? {
    switch self {
    case .bundleId(let id):
      id
    default:
      nil
    }
  }
}

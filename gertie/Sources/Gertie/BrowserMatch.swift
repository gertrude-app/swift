public enum BrowserMatch: Equatable, Sendable, Codable {
  case bundleId(String)
  case name(String)
}

public extension BrowserMatch {
  var name: String? {
    switch self {
    case .name(let name):
      return name
    default:
      return nil
    }
  }

  var bundleId: String? {
    switch self {
    case .bundleId(let id):
      return id
    default:
      return nil
    }
  }
}

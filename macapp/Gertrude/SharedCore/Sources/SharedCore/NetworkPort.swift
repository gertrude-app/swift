public enum NetworkPort: Equatable, Codable {
  case http(Int)
  case https(Int)
  case dns(Int)
  case other(Int)
  case unknown(Int)

  public init(_ int: Int) {
    switch int {
    case 80:
      self = .http(int)
    case 443:
      self = .https(int)
    case 53:
      self = .dns(int)
    default:
      self = .other(int)
    }
  }

  public init(_ string: String) {
    guard let int = Int(string) else {
      self = .unknown(-1)
      return
    }
    self = .init(int)
  }
}

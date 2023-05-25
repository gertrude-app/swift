public struct AppcastQuery: Codable {
  public var channel: ReleaseChannel?
  public var force: Bool?
  public var version: String?

  public init(channel: ReleaseChannel? = nil, force: Bool? = nil, version: String? = nil) {
    self.channel = channel
    self.force = force
    self.version = version
  }

  public var urlString: String {
    var dict: [String: String] = [:]
    if let channel = channel {
      dict["channel"] = channel.rawValue
    }
    if let force = force {
      dict["force"] = force ? "true" : "false"
    }
    if let version = version {
      dict["version"] = version
    }
    guard !dict.isEmpty else { return "" }
    return "?\(dict.map { "\($0)=\($1)" }.joined(separator: "&"))"
  }
}

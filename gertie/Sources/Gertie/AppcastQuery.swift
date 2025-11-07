public struct AppcastQuery: Codable {
  public var channel: ReleaseChannel?
  public var force: Bool?
  public var version: String?
  /// added, sent by apps >= v2.4.0
  public var requestingAppVersion: String?

  public init(
    channel: ReleaseChannel? = nil,
    force: Bool? = nil,
    version: String? = nil,
    requestingAppVersion: String? = nil,
  ) {
    self.channel = channel
    self.force = force
    self.version = version
    self.requestingAppVersion = requestingAppVersion
  }

  public var urlString: String {
    var dict: [String: String] = [:]
    if let channel {
      dict["channel"] = channel.rawValue
    }
    if let force {
      dict["force"] = force ? "true" : "false"
    }
    if let version {
      dict["version"] = version
    }
    if let requestingAppVersion {
      dict["requestingAppVersion"] = requestingAppVersion
    }
    guard !dict.isEmpty else { return "" }
    return "?\(dict.map { "\($0)=\($1)" }.joined(separator: "&"))"
  }
}

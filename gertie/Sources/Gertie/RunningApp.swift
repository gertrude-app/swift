public struct RunningApp {
  public var pid: Int32 /* pid_t = Int32 */
  public var bundleId: String
  public var bundleName: String?
  public var localizedName: String?
  public var launchable: Bool?

  var hasName: Bool {
    self.bundleName != nil || self.localizedName != nil
  }

  public init(
    pid: Int32 = Int32.max,
    bundleId: String,
    bundleName: String? = nil,
    localizedName: String? = nil,
    launchable: Bool? = nil
  ) {
    self.pid = pid
    self.bundleId = bundleId
    self.bundleName = bundleName
    self.localizedName = localizedName
    self.launchable = launchable
  }
}

// conformances

extension RunningApp: Equatable, Codable, Sendable, Hashable {}

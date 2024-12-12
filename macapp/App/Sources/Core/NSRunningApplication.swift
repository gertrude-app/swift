import AppKit

public extension NSRunningApplication {
  var name: String? {
    self.localizedName ?? self.bundleName
  }

  var bundleName: String? {
    guard let bundleURL = self.bundleURL else { return nil }
    guard let infoPlist = NSDictionary(
      contentsOf: bundleURL
        .appendingPathComponent("Contents/Info.plist")
    ) else { return nil }
    return infoPlist["CFBundleName"] as? String
  }
}

import Foundation

struct FilterBundle {
  private static var _bundle: Bundle?

  static var get: Bundle {
    if let bundle = _bundle {
      return bundle
    }

    let extensionsDirectoryURL = URL(
      fileURLWithPath: "Contents/Library/SystemExtensions",
      relativeTo: Bundle.main.bundleURL
    )
    let extensionURLs: [URL]
    do {
      extensionURLs = try FileManager.default.contentsOfDirectory(
        at: extensionsDirectoryURL,
        includingPropertiesForKeys: nil,
        options: .skipsHiddenFiles
      )
    } catch {
      fatalError(
        "Failed to get the contents of \(extensionsDirectoryURL.absoluteString): \(error.localizedDescription)"
      )
    }

    guard let extensionURL = extensionURLs.first else {
      fatalError("Failed to find any system extensions")
    }

    guard let extensionBundle = Bundle(url: extensionURL) else {
      fatalError("Failed to create a bundle with URL \(extensionURL.absoluteString)")
    }

    _bundle = extensionBundle
    return extensionBundle
  }

  static var identifier: String? {
    FilterBundle.get.bundleIdentifier
  }
}

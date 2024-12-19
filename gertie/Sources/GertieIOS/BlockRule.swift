public enum BlockRule {
  case bundleIdContains(String)
  case urlContains(String)
  case hostnameContains(String)
  case hostnameEquals(String)
  case hostnameEndsWith(String)
  case targetContains(String) // "target" = url ?? hostname
  indirect case both(BlockRule, BlockRule)
  indirect case unless(rule: BlockRule, negatedBy: [BlockRule])
}

public extension BlockRule {
  static var defaults: [BlockRule] {
    [
      .bundleIdContains("HashtagImagesExtension"),
      .bundleIdContains("com.apple.Spotlight"),
      .bundleIdContains(".com.apple.photoanalysisd"),
      .urlContains("tenor.co"),
      .targetContains("cdn2.smoot.apple.com"),
      .targetContains("tenor.co"),
      .targetContains("giphy.com"),
      .targetContains("media.fosu2-1.fna.whatsapp.net"),
      .both(.bundleIdContains("com.apple.MobileSMS"), .targetContains("ssl.mzstatic.com")),
      .both(
        .bundleIdContains("org.whispersystems.signal"),
        .targetContains("contentproxy.signal.org")
      ),
    ]
  }
}

// conformances

extension BlockRule: Equatable, Codable, Sendable, Hashable {}

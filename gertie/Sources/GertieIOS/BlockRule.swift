public enum BlockRule {
  case bundleIdContains(String)
  case urlContains(String)
  case hostnameContains(String)
  case hostnameEquals(String)
  case hostnameEndsWith(String)
  case targetContains(String) // "target" = url ?? hostname
  case flowTypeIs(FlowType)
  indirect case both(BlockRule, BlockRule)
  indirect case unless(rule: BlockRule, negatedBy: [BlockRule])
}

public extension BlockRule {
  static var typescriptAlias: String {
    """
      | { case: 'bundleIdContains'; value: string }
      | { case: 'urlContains'; value: string }
      | { case: 'hostnameContains'; value: string }
      | { case: 'hostnameEquals'; value: string }
      | { case: 'hostnameEndsWith'; value: string }
      | { case: 'targetContains'; value: string }
      | { case: 'flowTypeIs'; value: 'browser' | 'socket' }
      | { case: 'both'; first: BlockRule; second: BlockRule }
      | { case: 'unless'; rule: BlockRule; negatedBy: BlockRule[] }
    """
  }
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

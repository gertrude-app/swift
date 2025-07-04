/// Pre 1.4.x type, didn't have typescript-friendly encoding, now deprecated
/// but preserved exactly as it was for encoding/decoding stored legacy data
public extension BlockRule {
  enum Legacy {
    case bundleIdContains(String)
    case urlContains(String)
    case hostnameContains(String)
    case hostnameEquals(String)
    case hostnameEndsWith(String)
    case targetContains(String)
    case flowTypeIs(FlowType)
    indirect case both(BlockRule.Legacy, BlockRule.Legacy)
    indirect case unless(rule: BlockRule.Legacy, negatedBy: [BlockRule.Legacy])
  }

  var legacy: Legacy {
    switch self {
    case .both(let a, let b): .both(a.legacy, b.legacy)
    case .bundleIdContains(let bundleId): .bundleIdContains(bundleId)
    case .flowTypeIs(let flowType): .flowTypeIs(flowType)
    case .hostnameContains(let hostname): .hostnameContains(hostname)
    case .hostnameEndsWith(let hostname): .hostnameEndsWith(hostname)
    case .hostnameEquals(let hostname): .hostnameEquals(hostname)
    case .targetContains(let target): .targetContains(target)
    case .unless(let rule, let negatedBy): .unless(
        rule: rule.legacy,
        negatedBy: negatedBy.map(\.legacy)
      )
    case .urlContains(let url): .urlContains(url)
    }
  }
}

// extensions

public extension BlockRule.Legacy {
  static var defaults: [BlockRule.Legacy] {
    [
      .bundleIdContains("HashtagImagesExtension"),
      .bundleIdContains("com.apple.Spotlight"),
      .bundleIdContains(".com.apple.photoanalysisd"),
      .urlContains("tenor.co"),
      .targetContains("cdn2.smoot.apple.com"),
      .targetContains("tenor.co"),
      .targetContains("giphy.com"),
      .targetContains("media.fosu2-1.fna.whatsapp.net"),
      .both(
        .bundleIdContains("com.apple.MobileSMS"),
        .targetContains("ssl.mzstatic.com")
      ),
      .both(
        .bundleIdContains("org.whispersystems.signal"),
        .targetContains("contentproxy.signal.org")
      ),
    ]
  }
}

extension BlockRule.Legacy: Equatable, Codable, Sendable, Hashable {}

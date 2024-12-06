import GertieIOS
import IOSRoute

extension BlockRules: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    var rules = BlockRule.defaults
    switch input.vendorId?.lowercased {
    case "2cada392-9d09-4425-bec2-b0c4e3aeafec", // harriet
         "164e41e3-3fe8-455f-9f8c-ab674e19dd93": // charlie
      // totally kill app store from Messages
      rules.append(.both(
        .bundleIdContains(".com.apple.MobileSMS"),
        .targetContains("amp-api-edge.apps.apple.com")
      ))
      // prevent apple.com website access from settings webviews
      rules.append(.both(
        .bundleIdContains("com.apple.Preferences"),
        .targetContains("www.apple.com")
      ))
      rules.append(.both(
        .bundleIdContains("com.apple.Preferences"),
        .targetContains("support.apple.com")
      ))
    default:
      break
    }
    return rules
  }
}

import GertieIOS
import IOSRoute

extension BlockRules: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    var rules = BlockRule.defaults
    switch input.vendorId?.lowercased {
    case "2cada392-9d09-4425-bec2-b0c4e3aeafec": // harriet :)
      rules.append(.both(
        .bundleIdContains(".com.apple.MobileSMS"),
        .targetContains("amp-api-edge.apps.apple.com")
      ))
    default:
      break
    }
    return rules
  }
}

import Dependencies
import DuetSQL
import Gertie
import GertieIOS
import IOSRoute

extension BlockRules: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    @Dependency(\.logger) var logger

    // remove `BlockRules` pair when deprecation complete
    await context.db.logDeprecated("BlockRules(v1)")

    if let vendorId = input.vendorId {
      logger.info("Vendor ID: \(vendorId)")
    }

    if let version = input.version.flatMap({ Semver($0) }),
       version >= Semver(major: 1, minor: 2, patch: 0) {
      logger.info("1.2.x app")
      return try await IOSApp.BlockRule.query()
        .where(.isNull(.vendorId) .|| input.vendorId.map { .vendorId == $0 } ?? .never)
        .all(in: context.db)
        .map(\.rule.legacy)
    }

    var rules = BlockRule.Legacy.defaults
    switch input.vendorId?.lowercased {
    case "4412c950-03e3-4c54-8dc4-13ffe2b425e7": // Alia
      rules.append(.both(
        .bundleIdContains("notion.id"),
        .targetContains("img.notionusercontent.com"), // gifs in notion docs
      ))
    case "2cada392-9d09-4425-bec2-b0c4e3aeafec", // harriet
         "164e41e3-3fe8-455f-9f8c-ab674e19dd93": // charlie
      // totally kill app store from Messages
      rules.append(.both(
        .bundleIdContains(".com.apple.MobileSMS"),
        .targetContains("amp-api-edge.apps.apple.com"),
      ))
      // prevent apple.com website access from settings webviews
      rules.append(.both(
        .bundleIdContains("com.apple.Preferences"),
        .targetContains("www.apple.com"),
      ))
      rules.append(.both(
        .bundleIdContains("com.apple.Preferences"),
        .targetContains("support.apple.com"),
      ))
    default:
      break
    }
    return rules
  }
}

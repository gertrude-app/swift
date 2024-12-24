import Dependencies
import DuetSQL
import Gertie
import GertieIOS
import IOSRoute

extension BlockRules: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    @Dependency(\.logger) var logger

    if let vendorId = input.vendorId {
      logger.info("Vendor ID: \(vendorId)")
    }

    if let version = input.version.flatMap({ Semver($0) }),
       version >= Semver(major: 1, minor: 2, patch: 0) {
      logger.info("1.2.x app")
      // await with(dependency: \.slack)
      //   .sysLog("1.2.x app, vendorId: \(input.vendorId?.lowercased ?? "(nil)")")
      return try await IOSBlockRule.query()
        // .where(.isNull(.vendorId) .|| input.vendorId.map { .vendorId == $0 } ?? .never)
        .where(
          .isNull(.vendorId) .|| .vendorId ==
            .uuid(UUID(uuidString: "d85bc297-2db6-4859-a073-00b5eddda8e1")!)
        )
        .all(in: context.db)
        .map(\.rule)
    }

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
    case "ac539f44-563c-485f-98cd-caf4fc323e69": // winfield
      // apple maps, no images
      rules.append(.both(.bundleIdContains(".com.apple.Maps"), .targetContains("ssl.mzstatic.com")))
      rules.append(.both(.bundleIdContains(".com.apple.Maps"), .targetContains("yelpcdn.com")))
      rules.append(.both(
        .bundleIdContains(".com.apple.Maps"),
        .targetContains("4sqi.net") // foursquare
      ))
      rules.append(.both(.bundleIdContains(".com.apple.Maps"), .targetContains("tripadvisor.com")))
      rules.append(.both(.bundleIdContains(".com.apple.Maps"), .targetContains("itunes.apple.com")))
      rules.append(.bundleIdContains("com.apple.mobileassetd.client.Maps"))
      rules
        .append(.both(
          .bundleIdContains(".com.apple.Maps"),
          .targetContains("amp-api.apps.apple.com")
        ))
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

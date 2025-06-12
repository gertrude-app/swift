import Dependencies
import DuetSQL
import Gertie
import GertieIOS
import IOSRoute

extension BlockRules_v2: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    with(dependency: \.logger).info("BlockRules_v2: \(input)")
    let groupIds = input.disabledGroups.map { Postgres.Data.uuid($0.blockGroupId) }
    return try await IOSApp.BlockRule.query()
      .where(.or(
        .not(.isNull(.groupId)) .&& .groupId |!=| groupIds,
        .vendorId == (input.vendorId == .init(.zero) ? .init() : input.vendorId)
      ))
      .orderBy(.id, .asc)
      .all(in: ctx.db)
      .map(\.rule)
  }
}

// extensions

public extension GertieIOS.BlockGroup {
  var blockGroupId: UUID {
    let ids = CreateBlockGroups.GroupIds()
    return switch self {
    case .gifs: ids.gifs
    case .appleMapsImages: ids.appleMapsImages
    case .aiFeatures: ids.aiFeatures
    case .appStoreImages: ids.appStoreImages
    case .spotlightSearches: ids.spotlightSearches
    case .ads: ids.ads
    case .whatsAppFeatures: ids.whatsAppFeatures
    case .appleWebsite: ids.appleWebsite
    }
  }

  var blockGroupName: String {
    switch self {
    case .gifs: "GIFs"
    case .appleMapsImages: "Apple Maps images"
    case .aiFeatures: "AI features"
    case .appStoreImages: "App store images"
    case .spotlightSearches: "Spotlight"
    case .ads: "Ads"
    case .whatsAppFeatures: "WhatsApp"
    case .appleWebsite: "apple.com"
    }
  }
}

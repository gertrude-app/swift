public enum BlockGroup: String {
  case gifs
  case appleMapsImages
  case aiFeatures
  case appStoreImages
  case spotlightSearches
  case ads
  case whatsAppFeatures
  case appleWebsite
}

public extension [BlockGroup] {
  static var all: [BlockGroup] {
    [
      .gifs,
      .appleMapsImages,
      .aiFeatures,
      .appStoreImages,
      .spotlightSearches,
      .ads,
      .whatsAppFeatures,
      .appleWebsite,
    ]
  }
}

public extension RangeReplaceableCollection where Element == BlockGroup {
  mutating func toggle(_ blockGroup: BlockGroup) {
    if self.contains(blockGroup) {
      self.removeAll { $0 == blockGroup }
    } else {
      self.append(blockGroup)
    }
  }
}

// conformances

extension BlockGroup: Sendable, Hashable, Codable, Equatable, CaseIterable {}

extension BlockGroup: Identifiable {
  public var id: String { "\(self)" }
}

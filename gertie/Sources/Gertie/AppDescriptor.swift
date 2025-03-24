public struct AppDescriptor: Equatable, Codable, Sendable {
  public let bundleId: String
  public let slug: String?
  public let displayName: String?
  public let categories: Set<String>

  public init(
    bundleId: String,
    slug: String? = nil,
    displayName: String? = nil,
    categories: Set<String> = []
  ) {
    self.bundleId = bundleId
    self.slug = slug
    self.displayName = displayName
    self.categories = categories
  }
}

// extensions

extension AppDescriptor: CustomStringConvertible {
  public var shortDescription: String {
    var desc = self.displayName ?? self.slug ?? self.bundleId
    if !self.categories.isEmpty {
      desc += " \(self.categories.sorted().map { "category:\($0)" }.joined(separator: " "))"
    }
    return desc
  }

  public var description: String {
    if self.slug == nil, displayName == nil, self.categories.isEmpty {
      return self.bundleId
    }

    var desc = ""
    var suffix = ""
    if let displayName {
      desc = "\"\(displayName)\" ("
      suffix = ")"
    }

    var subParts: [String?] = [slug != nil ? "app:\(self.slug!)" : nil]
    subParts += self.categories.sorted().map { "category:\($0)" }
    subParts.append(self.bundleId)

    return desc + subParts.compactMap(\.self).joined(separator: ", ") + suffix
  }
}

#if DEBUG
  public extension AppDescriptor {
    static let mock = AppDescriptor(bundleId: "com.mock.app")
  }
#endif

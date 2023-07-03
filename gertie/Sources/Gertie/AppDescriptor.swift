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
    var desc = displayName ?? slug ?? bundleId
    if !categories.isEmpty {
      desc += " \(categories.sorted().map { "category:\($0)" }.joined(separator: " "))"
    }
    return desc
  }

  public var description: String {
    if slug == nil, displayName == nil, categories.isEmpty {
      return bundleId
    }

    var desc = ""
    var suffix = ""
    if let displayName = displayName {
      desc = "\"\(displayName)\" ("
      suffix = ")"
    }

    var subParts: [String?] = [slug != nil ? "app:\(slug!)" : nil]
    subParts += categories.sorted().map { "category:\($0)" }
    subParts.append(bundleId)

    return desc + subParts.compactMap { $0 }.joined(separator: ", ") + suffix
  }
}

#if DEBUG
  public extension AppDescriptor {
    static let mock = AppDescriptor(bundleId: "com.mock.app")
  }
#endif

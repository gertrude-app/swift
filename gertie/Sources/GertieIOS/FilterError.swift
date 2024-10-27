public enum FilterError: Error, Equatable, Hashable, Sendable {
  case noRulesFound
  case rulesDecodeFailed
}

public extension FilterError {
  static var urlSlug: String {
    "ios-filter-errors"
  }

  var urlSlug: String {
    switch self {
    case .noRulesFound:
      return "no-rules-found"
    case .rulesDecodeFailed:
      return "rules-decode-failed"
    }
  }
}

public extension String.StringInterpolation {
  mutating func appendInterpolation(filterErr: FilterError) {
    self.appendLiteral(filterErr.urlSlug)
  }
}

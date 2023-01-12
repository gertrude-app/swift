import Foundation
import Shared

public extension String {
  // "501,502" -> Set<uid_t> [501, 502]
  func parseCommaSeparatedUserIds() -> Set<uid_t> {
    Set(
      trimmingCharacters(in: .whitespaces)
        .components(separatedBy: ",")
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { $0 != "" }
        .compactMap { UInt32($0) as uid_t? }
    )
  }

  init(fromUserIds ids: Set<uid_t>) {
    self = ids.map { String($0) }.joined(separator: ",")
  }

  func removeSuffix(_ suffix: String) -> String {
    if !hasSuffix(suffix) {
      return self
    }
    return String(prefix(count - suffix.count))
  }

  func removeSuffix(_ suffixes: [String]) -> String {
    for suffix in suffixes {
      if hasSuffix(suffix) {
        return removeSuffix(suffix)
      }
    }
    return self
  }
}

import Foundation

public extension String {
  var snakeCased: String {
    self.processCamelCaseRegex(pattern: acronymPattern)?
      .processCamelCaseRegex(pattern: normalPattern)?.lowercased() ?? lowercased()
  }

  var shoutyCased: String {
    self.snakeCased.uppercased()
  }

  func padLeft(toLength length: Int, withPad pad: Character) -> String {
    String(
      String(reversed())
        .padding(toLength: length, withPad: "\(pad)", startingAt: 0)
        .reversed()
    )
  }

  func regexReplace<Pattern: StringProtocol, Replacement: StringProtocol>(
    _ pattern: Pattern,
    _ replacement: Replacement
  ) -> String {
    replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
  }

  func regexRemove<Pattern: StringProtocol>(_ pattern: Pattern) -> String {
    self.regexReplace(pattern, "")
  }

  func matchesRegex<Pattern: StringProtocol>(_ pattern: Pattern) -> Bool {
    range(of: pattern, options: .regularExpression) != nil
  }

  private func processCamelCaseRegex(pattern: String) -> String? {
    let regex = try? NSRegularExpression(pattern: pattern, options: [])
    let range = NSRange(location: 0, length: count)
    return regex?.stringByReplacingMatches(
      in: self,
      options: [],
      range: range,
      withTemplate: "$1_$2"
    )
  }
}

private let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
private let normalPattern = "([a-z0-9])([A-Z])"

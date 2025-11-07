import Foundation

public extension String {
  var snakeCased: String {
    self.processCamelCaseRegex(pattern: acronymPattern)?
      .processCamelCaseRegex(pattern: normalPattern)?.lowercased() ?? lowercased()
  }

  var shoutyCased: String {
    self.snakeCased.uppercased()
  }

  var slugified: String {
    self
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
      .replacingOccurrences(of: ".", with: "-")
      .replacingOccurrences(of: " ", with: "-")
      .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
  }

  func padLeft(toLength length: Int, withPad pad: Character) -> String {
    String(
      String(reversed())
        .padding(toLength: length, withPad: "\(pad)", startingAt: 0)
        .reversed(),
    )
  }

  func regexReplace(
    _ pattern: some StringProtocol,
    _ replacement: some StringProtocol,
  ) -> String {
    replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
  }

  func regexRemove(_ pattern: some StringProtocol) -> String {
    self.regexReplace(pattern, "")
  }

  func matchesRegex(_ pattern: some StringProtocol) -> Bool {
    range(of: pattern, options: .regularExpression) != nil
  }

  private func processCamelCaseRegex(pattern: String) -> String? {
    let regex = try? NSRegularExpression(pattern: pattern, options: [])
    let range = NSRange(location: 0, length: count)
    return regex?.stringByReplacingMatches(
      in: self,
      options: [],
      range: range,
      withTemplate: "$1_$2",
    )
  }
}

private let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
private let normalPattern = "([a-z0-9])([A-Z])"

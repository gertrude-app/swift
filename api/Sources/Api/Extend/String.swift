import Foundation

extension String {
  var isValidEmail: Bool {
    let parts = split(separator: "@")
    return parts.count == 2 && parts[0].count > 0 && parts[1].count > 3 && parts[1].contains(".")
  }

  var withEmailSubjectDisambiguator: String {
    let ref = UUID().lowercased.split(separator: "-").first!
    return "\(self) [ref:\(ref.prefix(5))]"
  }

  var singular: String {
    regexReplace("ies$", "y").regexReplace("s$", "")
  }
}

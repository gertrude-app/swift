import DuetSQL
import MacAppRoute

extension ReportBrowsers: Resolver {
  static func resolve(with input: Input, in context: UserContext) async throws -> Output {
    let existing = try await Browser.query().all()
    let existingBundleIds = existing.map(\.match).compactMap(\.bundleId)
    let new = input.filter { !existingBundleIds.contains($0.bundleId) }

    if !new.isEmpty {
      try await Browser.create(new.map { .init(match: .bundleId($0.bundleId)) })
      await Current.slack.sysLog("""
        *Received new browser bundle ids:*
        \(new.map(\.slack).joined(separator: "\n"))
      """)
    }

    return .success
  }
}

extension ReportBrowsers.BrowserInput {
  var slack: String {
    "- name: `\(name)` -> bundleId: `\(bundleId)`"
  }
}

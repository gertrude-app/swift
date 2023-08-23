import DuetSQL
import Gertie
import Vapor

enum AppcastRoute {
  static func handler(_ request: Request) async throws -> Response {
    let query = try request.query.decode(AppcastQuery.self)
    let releases = try await Current.db.query(Release.self)
      .where(query.version.map { _ in .always } ?? (.channel == query.channel ?? .stable))
      .where(query.version.map { .semver == $0 } ?? .always)
      .orderBy(.createdAt, .desc)
      .all()

    return Response(
      headers: ["Content-Type": "application/xml"],
      body: .init(string: feedXml(
        for: releases,
        force: query.force == true || query.version != nil
      ))
    )
  }
}

// helpers

func feedXml(for releases: [Release], force: Bool = false) -> String {
  let items = releases.enumerated().map { index, release in
    release.sparkleItemXml(forceUpdate: force && index == 0)
  }.joined(separator: "\n")

  return """
  <?xml version="1.0" standalone="yes"?>
  <rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
    <channel>
      <title>Gertrude</title>
      \(items)
    </channel>
  </rss>
  """
}

extension Release {
  func sparkleItemXml(forceUpdate: Bool = false) -> String {
    let description = notes.map { "\n  <description><![CDATA[\($0)]]></description>" } ?? ""
    let formatter = DateFormatter()
    formatter.timeZone = .init(abbreviation: "UTC")
    formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
    return """
    <item>
      <title>\(forceUpdate ? "99.99.99" : semver)</title>
      <pubDate>\(formatter.string(from: createdAt))</pubDate>
      <sparkle:version>\(forceUpdate ? "99.99.99" : semver)</sparkle:version>
      <sparkle:shortVersionString>\(forceUpdate ? "99.99.99" : semver)</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>10.15</sparkle:minimumSystemVersion>
      <enclosure
        url="\(Env.CLOUD_STORAGE_BUCKET_URL)/releases/Gertrude.\(semver).zip"
        length="\(length)"
        type="application/octet-stream"
        sparkle:edSignature="\(signature)"
      />\(description)
    </item>
    """
  }
}

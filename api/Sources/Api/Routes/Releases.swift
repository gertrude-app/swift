import Dependencies
import Gertie
import Vapor
import XCore

enum ReleasesRoute {
  @Sendable static func handler(_ request: Request) async throws -> Response {
    struct Item: Encodable {
      var version: String
      var channel: ReleaseChannel
    }

    let releases = try await request.context.db.query(Release.self)
      .orderBy(.createdAt, .desc)
      .all(in: request.context.db)

    let items = releases.map {
      Item(version: $0.semver, channel: $0.channel)
    }

    return Response(
      headers: ["Content-Type": "application/json"],
      body: .init(string: try JSON.encode(items))
    )
  }
}

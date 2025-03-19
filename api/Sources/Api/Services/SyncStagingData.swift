import AsyncHTTPClient
import Dependencies
import DuetSQL
import Foundation
import NIOFoundationCompat
import Vapor
import XCore

enum DumpStagingDataRoute {
  @Sendable static func handler(_ request: Request) async throws -> some AsyncResponseEncodable {
    @Dependency(\.db) var db
    @Dependency(\.env) var env

    guard let reqToken = request.parameters.getUUID("token"),
          let envToken = env.getUUID("SYNC_STAGING_TOKEN"),
          reqToken == envToken,
          env.mode != .staging else {
      throw Abort(.notFound)
    }

    var keychains = try await Keychain.query()
      .where(.isPublic == true)
      .all(in: db)
    for i in 0 ..< keychains.count {
      keychains[i].parentId = .stagingPublicKeychainOwner
    }

    return try await SyncStagingData(
      keychains: keychains,
      keys: Key.query()
        .where(.keychainId |=| keychains.map(\.id))
        .all(in: db),
      appBundleIds: AppBundleId.query().all(in: db),
      appCategories: AppCategory.query().all(in: db),
      identifiedApps: IdentifiedApp.query().all(in: db)
    )
  }
}

struct SyncStagingDataCommand: AsyncCommand {
  struct Signature: CommandSignature {}
  var help: String { "Sync staging data" }

  @Dependency(\.db) var db
  @Dependency(\.env) var env
  @Dependency(\.logger) var logger

  func run(using context: CommandContext, signature: Signature) async throws {
    switch await self.exec(client: context.application.http.client.shared) {
    case .success:
      self.logger.info("Synced staging data")
    case .failure(let error):
      self.logger.error("Error syncing staging data: \(error)")
    }
  }

  func exec(client: HTTPClient) async -> Result<Void, StringError> {
    guard self.env.mode != .prod, let token = env.getUUID("SYNC_STAGING_TOKEN") else {
      return .failure("No SYNC_STAGING_TOKEN")
    }

    let dataResult = await fetchData(client, token)
    guard case .success(let data) = dataResult else {
      return dataResult.map { _ in () }
    }

    do {
      try await self.db.delete(all: AppBundleId.self)
      try await self.db.delete(all: IdentifiedApp.self)
      try await self.db.delete(all: AppCategory.self)
      try await self.db.create(data.appCategories)
      try await self.db.create(data.identifiedApps)
      try await self.db.create(data.appBundleIds)

      try await Reset.ensurePublicKeychainOwner()
      try await Keychain.query()
        .where(.id |=| data.keychains.map(\.id))
        .delete(in: self.db)
      try await self.db.create(data.keychains)
      try await self.db.create(data.keys)
      return .success(())
    } catch {
      return .failure("Error saving staging data: \(error)")
    }
  }

  func fetchData(
    _ client: HTTPClient,
    _ token: UUID
  ) async -> Result<SyncStagingData, StringError> {
    do {
      let request =
        HTTPClientRequest(url: "https://api.gertrude.app/dump-staging-data/\(token.lowercased)")
      let response = try await client.execute(request, timeout: .seconds(5))
      guard response.status == .ok else {
        return .failure("Unexpected status syncing staging data: \(response.status)")
      }
      let buf = try await response.body.collect(upTo: 1024 * 1024) // 1 MB
      guard let json = buf.getString(at: 0, length: buf.readableBytes, encoding: .utf8) else {
        return .failure("Error converting buffer to string")
      }
      let data = try JSON.decode(json, as: SyncStagingData.self, [.isoDates])
      return .success(data)
    } catch {
      return .failure("Error syncing staging data: \(error)")
    }
  }
}

struct SyncStagingData: Content {
  var keychains: [Keychain]
  var keys: [Key]
  var appBundleIds: [AppBundleId]
  var appCategories: [AppCategory]
  var identifiedApps: [IdentifiedApp]
}

extension Admin.Id {
  static let stagingPublicKeychainOwner =
    Self(UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!)
}

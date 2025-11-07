import Dependencies
import DuetSQL
import Foundation
import Vapor
import XCore

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

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
      identifiedApps: IdentifiedApp.query().all(in: db),
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
    switch await self.exec() {
    case .success:
      self.logger.info("Synced staging data")
    case .failure(let error):
      self.logger.error("Error syncing staging data: \(error)")
    }
  }

  func exec() async -> Result<Void, StringError> {
    guard self.env.mode != .prod, let token = env.getUUID("SYNC_STAGING_TOKEN") else {
      return .failure("No SYNC_STAGING_TOKEN")
    }

    let dataResult = await fetchData(token)
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

  func fetchData(_ token: UUID) async -> Result<SyncStagingData, StringError> {
    do {
      guard let url = URL(string: "https://api.gertrude.app/dump-staging-data/\(token.lowercased)")
      else {
        return .failure("Invalid URL")
      }

      var request = URLRequest(url: url)
      request.timeoutInterval = 5

      let (data, response) = try await URLSession.shared.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse else {
        return .failure("Invalid response type")
      }

      guard httpResponse.statusCode == 200 else {
        return .failure("Unexpected status syncing staging data: \(httpResponse.statusCode)")
      }

      guard let json = String(data: data, encoding: .utf8) else {
        return .failure("Error converting data to string")
      }

      let syncData = try JSON.decode(json, as: SyncStagingData.self, [.isoDates])
      return .success(syncData)
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

extension Parent.Id {
  static let stagingPublicKeychainOwner =
    Self(UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!)
}

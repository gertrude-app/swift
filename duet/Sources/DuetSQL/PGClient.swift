import FluentKit
import FluentPostgresDriver

public struct PgClient: Client {
  public let db: SQLDatabase

  public init(
    config: PostgresKit.SQLPostgresConfiguration,
    logger: Logger? = nil,
    numberOfThreads: Int = 1,
  ) {
    self.init(
      factory: DatabaseConfigurationFactory.postgres(configuration: config),
      logger: logger,
      numberOfThreads: numberOfThreads,
    )
  }

  public init(
    factory: DatabaseConfigurationFactory,
    logger: Logger? = nil,
    numberOfThreads: Int = 1,
  ) {
    let configuration = factory.make()
    let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: numberOfThreads).any()
    let threadPool = NIOThreadPool(numberOfThreads: numberOfThreads)
    let driver = configuration.makeDriver(for: Databases(threadPool: threadPool, on: eventLoop))
    let context = DatabaseContext(
      configuration: configuration,
      logger: logger ?? Logger(label: "DuetSQL.PgClient"),
      eventLoop: eventLoop,
    )
    self.db = driver.makeDatabase(with: context) as! SQLDatabase
    self._shutdownHelper = ShutdownHelper(driver)
  }

  public func execute(statement: SQL.Statement) async throws -> [SQLRow] {
    #if !DEBUG
      return try await self.db.raw(statement.sql).all()
    #else
      do {
        return try await self.db.raw(statement.sql).all()
      } catch {
        print(String(reflecting: error))
        #if !os(Linux)
          fflush(stdout)
        #endif
        throw error
      }
    #endif
  }

  public func execute<M: DuetSQL.Model>(
    statement: SQL.Statement,
    returning: M.Type,
  ) async throws -> [M] {
    #if !DEBUG
      let rows = try await self.db.raw(statement.sql).all()
      return try rows.compactMap { row in try row.decode(M.self) }
    #else
      do {
        let rows = try await self.db.raw(statement.sql).all()
        return try rows.compactMap { row in try row.decode(M.self) }
      } catch {
        print(String(reflecting: error))
        #if !os(Linux)
          fflush(stdout)
        #endif
        throw error
      }
    #endif
  }

  public func execute(raw: SQLQueryString) async throws -> [SQLRow] {
    try await self.db.raw(raw).all()
  }

  private let _shutdownHelper: ShutdownHelper
}

extension PgClient {
  private final class ShutdownHelper: Sendable {
    let driver: any DatabaseDriver

    init(_ driver: any DatabaseDriver) {
      self.driver = driver
    }

    deinit {
      self.driver.shutdown()
    }
  }
}

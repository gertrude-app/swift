import Vapor

public extension Configure {
  static func jobs(_ app: Application) throws {
    app.queues.use(.fluent())
    app.queues.configuration.workerCount = 1
    app.queues.configuration.refreshInterval = .seconds(300)

    app.queues.schedule(CleanupJob()).daily().at(2, 30, .am)
    app.queues.schedule(SubscriptionManager()).daily().at(6, 30, .am)
    app.queues.schedule(DiskSpaceJob()).hourly().at(0)
    app.queues.schedule(CrashReporterJob()).hourly().at(25)

    try app.queues.startScheduledJobs()

    app.asyncCommands.use(ResetCommand(), as: "reset")
    app.asyncCommands.use(SyncStagingDataCommand(), as: "sync-staging-data")
  }
}

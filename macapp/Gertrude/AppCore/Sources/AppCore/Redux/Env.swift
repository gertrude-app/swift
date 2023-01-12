import Shared
import SharedCore

struct Env {
  var api: ApiClient
  var appVersion: String
  var connection: ConnectionClient
  var deviceStorage: DeviceStorageClient
  var filter: FilterClient
  var healthCheck: HealthCheckClient
  var honeycomb: Honeycomb.Client
  var logger: GertieLogger
  var os: OsClient
  var screenshot: ScreenshotClient
}

extension Env {
  static var live = Env(
    api: .live,
    appVersion: "(unknown)",
    connection: .live,
    deviceStorage: .live,
    filter: .live,
    healthCheck: .live,
    honeycomb: .live,
    logger: {
      // this temporary `launch` logger ensures that
      // during the brief window of app launch, before we
      // can configure an app logger based on a store:
      //   a) we are logging to honeycomb
      //   b) we are logging to the OS Console.app
      let launchLogger = AppLogger(store: nil)
      launchLogger.console = isDev() ? NullLogger() : OsLogger()
      return launchLogger
    }(),
    os: .live,
    screenshot: .live
  )
}

extension Env {
  static let noop = Env(
    api: .noop,
    appVersion: "5.5.5-beta.noop",
    connection: .connected,
    deviceStorage: .noop,
    filter: .noop,
    healthCheck: .noop,
    honeycomb: .noop,
    logger: GertieNullLogger(),
    os: .noop,
    screenshot: .noop
  )
}

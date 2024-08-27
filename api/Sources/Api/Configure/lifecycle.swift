import Vapor

public extension Configure {
  static func lifecycleHandlers(_ app: Application) {
    app.lifecycle.use(ApiLifecyle())
  }
}

struct ApiLifecyle: LifecycleHandler {
  func shutdownAsync(_ app: Application) async {
    Current.logger.info("Shutting down...")
    await Current.websockets.disconnectAll()
  }
}

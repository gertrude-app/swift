import DuetSQL
import Gertie
import Vapor

enum LegacyAppWebsocket {
  static func handler(_ request: Request, _ ws: WebSocket) {
    Task {
      do {
        try await establish(request, ws)
      } catch is UserTokenNotFound {
        Current.logger.debug("WS: failed to establish connection: user token not found")
        try await ws.close(code: .init(codeNumber: Int(WebsocketMsg.Error.USER_TOKEN_NOT_FOUND)))
      } catch {
        Current.logger.error("websocket error: \(error)")
        try await ws.close()
      }
    }
  }

  private static func establish(_ request: Request, _ ws: WebSocket) async throws {
    guard let token = try? await request.userToken(),
          let userDevice = try? await token.userDevice() else {
      throw UserTokenNotFound()
    }

    let user = try await token.user()
    let keychains = try await user.keychains()

    let entityIds = LegacyAppConnection.Ids(
      userDevice: userDevice.id,
      user: user.id,
      keychains: keychains.map(\.id)
    )

    Current.logger.debug("WS: adding connection UserDevice: \(userDevice.id.lowercased)")
    let connection = LegacyAppConnection(ws: ws, ids: entityIds)
    await Current.legacyConnectedApps.add(connection)
  }
}

extension LegacyAppWebsocket {
  struct UserTokenNotFound: Error {}
}

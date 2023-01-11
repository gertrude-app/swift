import DuetSQL
import Shared
import Vapor

enum AppWebsocket {
  static func handler(_ request: Request, _ ws: WebSocket) {
    Task {
      do {
        try await establish(request, ws)
      } catch is UserTokenNotFound {
        Current.logger.notice("WS: failed to establish connection: user token not found")
        try await ws.close(code: .init(codeNumber: Int(WebsocketMsg.Error.USER_TOKEN_NOT_FOUND)))
      } catch {
        Current.logger.error("websocket error: \(error)")
        try await ws.close()
      }
    }
  }

  private static func establish(_ request: Request, _ ws: WebSocket) async throws {
    guard let token = try? await request.userToken(),
          let device = try? await token.device() else {
      throw UserTokenNotFound()
    }

    let user = try await token.user()
    let keychains = try await user.keychains()

    let entityIds = AppConnection.Ids(
      device: device.id,
      user: user.id,
      keychains: keychains.map(\.id)
    )

    Current.logger.notice("WS: adding connection Device: \(device.id.lowercased)")
    let connection = AppConnection(ws: ws, ids: entityIds)
    await Current.connectedApps.add(connection)
  }
}

extension AppWebsocket {
  struct UserTokenNotFound: Error {}
}

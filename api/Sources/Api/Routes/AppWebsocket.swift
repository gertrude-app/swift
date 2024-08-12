import DuetSQL
import Gertie
import Vapor
import WebSocketKit

enum AppWebsocket {
  @Sendable static func handler(_ request: Request, _ ws: WebSocket) async {
    do {
      try await self.establish(request, ws)
    } catch is UserTokenNotFound {
      Current.logger.debug("WebSocket conn err: user token not found (ws)")
      let code = Int(WebSocketMessage.ErrorCode.userTokenNotFound.rawValue)
      try? await ws.close(code: .init(codeNumber: code))
    } catch {
      Current.logger.error("WebSocket unexpected conn err (ws): \(error)")
      try? await ws.close()
    }
  }

  private static func establish(
    _ request: Request,
    _ ws: WebSocket
  ) async throws {
    guard let token = try? await request.userToken(),
          let userDevice = try? await token.userDevice() else {
      throw UserTokenNotFound()
    }

    let user = try await token.user()
    let keychains = try await user.keychains()

    let entityIds = AppConnection.Ids(
      userDevice: userDevice.id,
      user: user.id,
      keychains: keychains.map(\.id)
    )

    let connection = AppConnection(ws: ws, ids: entityIds)
    await Current.connectedApps.add(connection)
  }
}

extension AppWebsocket {
  struct UserTokenNotFound: Error {}
}

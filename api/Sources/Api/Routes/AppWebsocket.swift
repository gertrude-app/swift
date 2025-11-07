import DuetSQL
import Gertie
import Vapor
import WebSocketKit

enum AppWebsocket {
  @Sendable static func handler(_ request: Request, _ ws: WebSocket) async {
    do {
      try await self.establish(request, ws)
    } catch is ChildMacAppTokenNotFound {
      request.logger.debug("WebSocket conn err: child mac app token not found (ws)")
      let code = Int(WebSocketMessage.ErrorCode.userTokenNotFound.rawValue)
      try? await ws.close(code: .init(codeNumber: code))
    } catch {
      request.logger.error("WebSocket unexpected conn err (ws): \(error)")
      try? await ws.close()
    }
  }

  private static func establish(
    _ req: Request,
    _ ws: WebSocket,
  ) async throws {
    guard let token = try? await req.macAppToken(),
          let computerUser = try? await token.computerUser(in: req.context.db) else {
      throw ChildMacAppTokenNotFound()
    }

    let child = try await token.child(in: req.context.db)
    let keychains = try await child.keychains(in: req.context.db)

    let ids = AppConnection.Ids(
      computerUser: computerUser.id,
      child: child.id,
      keychains: keychains.map(\.id),
    )

    let connection = AppConnection(ws: ws, ids: ids)
    await with(dependency: \.websockets).add(connection)
  }
}

extension AppWebsocket {
  struct ChildMacAppTokenNotFound: Error {}
}

import DuetSQL
import Foundation
import PairQL
import TypescriptPairQL
import Vapor

struct DashboardContext {
  let dashboardUrl: String
}

enum DashboardRoute: PairRoute {
  case adminAuthed(UUID, AuthedAdminRoute)
  case unauthed(UnauthedRoute)
}

extension DashboardRoute {
  static let router = OneOf {
    Route(/Self.adminAuthed) {
      Headers { Field("X-AdminToken") { UUID.parser() } }
      AuthedAdminRoute.router
    }
    Route(/Self.unauthed) {
      UnauthedRoute.router
    }
  }
}

extension DashboardRoute: RouteResponder {
  static func respond(to route: Self, in context: DashboardContext) async throws -> Response {
    switch route {
    case .adminAuthed(let uuid, let adminRoute):
      let token = try await Current.db.query(AdminToken.self)
        .where(.value == uuid)
        .first()
      let admin = try await Current.db.query(Admin.self)
        .where(.id == token.adminId)
        .first()
      let adminContext = AdminContext(dashboardUrl: context.dashboardUrl, admin: admin)
      return try await AuthedAdminRoute.respond(to: adminRoute, in: adminContext)
    case .unauthed(let route):
      fatalError("so not implemented \(route)")
    }
  }
}

// TODO: lol
func pattern<P: TypescriptPair>(type: P.Type) -> String {
  """
  export namespace \(P.self) {
    \(P.Input.ts.replacingOccurrences(of: "__self__", with: "Input"))

    \(P.Output.ts.replacingOccurrences(of: "__self__", with: "Output"))

    export async function send(input: Input): Promise<PqlResult<Output>> {
      return pqlQuery<Input, Output>(input, ClientAuth.\(P.auth), `\(P.name)`)
    }
  }
  """
}

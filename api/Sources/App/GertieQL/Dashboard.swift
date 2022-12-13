import DashboardRoute
import DuetSQL
import TypescriptPairQL
import Vapor

extension DashboardRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {
    case .adminAuthed(let uuid, let adminRoute):
      let token = try await Current.db.query(AdminToken.self)
        .where(.value == uuid)
        .first()
      let admin = try await Current.db.query(Admin.self)
        .where(.id == token.adminId)
        .first()
      let adminContext = AdminContext(request: context.request, admin: admin)
      return try await AuthedAdminRoute.respond(to: adminRoute, in: adminContext)
    case .unauthed(let route):
      fatalError("not implemented \(route)")
    }
  }
}

extension TsCodegen: NoInputPairResolver {
  static func resolve(in context: Context) async throws -> [String: String] {
    [:]
  }
}

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

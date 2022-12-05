import GertieQL
import Vapor

struct Context {
  let request: Request
}

protocol PairResolver: Pair {
  associatedtype Context
  static func resolve(for input: Input, in context: Context) async throws -> Output
}

protocol RouteResponder {
  associatedtype Context
  static func respond(to route: Self, in context: Context) async throws -> Response
}

extension RouteResponder {
  static func respond<T: PairOutput>(with output: T) async throws -> Response {
    try output.response()
  }
}

extension PairOutput {
  func response() throws -> Response {
    Response(
      status: .ok,
      headers: ["Content-Type": "application/json"],
      body: .init(data: try jsonData())
    )
  }
}

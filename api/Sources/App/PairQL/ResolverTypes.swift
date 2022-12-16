import PairQL
import Vapor

protocol PairResolver: Pair {
  associatedtype Context
  static func resolve(for input: Input, in context: Context) async throws -> Output
}

protocol NoInputPairResolver: Pair where Input == NoInput {
  associatedtype Context
  static func resolve(in context: Context) async throws -> Output
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

extension PairResolver {
  static func result(for input: Input, in context: Context) async -> Result<Output, Error> {
    do {
      return .success(try await resolve(for: input, in: context))
    } catch {
      return .failure(error)
    }
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
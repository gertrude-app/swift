import ClientInterfaces
import Foundation
import MacAppRoute
import XCore

func output<T: Pair>(
  from pair: T.Type,
  with route: AuthedUserRoute
) async throws -> T.Output {
  guard let token = await userToken.value else {
    throw ApiClient.Error.missingUserToken
  }
  return try await request(root: .userAuthed(token, route), pair: T.self)
}

func output<T: Pair>(
  from pair: T.Type,
  withUnauthed route: UnauthedRoute
) async throws -> T.Output {
  try await request(root: .unauthed(route), pair: T.self)
}

// helpers

private func request<T: Pair>(
  root route: MacAppRoute,
  pair: T.Type
) async throws -> T.Output {
  let router = App.router.baseURL(ApiClient.endpoint.absoluteString)
  let request = try router.request(for: .wrap(route))
  let (data, response) = try await data(for: request)
  if let httpResponse = response as? HTTPURLResponse,
     httpResponse.statusCode >= 300 {
    if let pqlError = try? JSON.decode(data, as: PqlError.self) {
      throw pqlError
    } else {
      throw ApiClient.Error.unexpectedError(statusCode: httpResponse.statusCode)
    }
  }
  return try JSON.decode(data, as: T.Output.self, [.isoDates])
}

// URLSession.data(for:) not available till macOS 12
private func data(for request: URLRequest) async throws -> (Data, URLResponse) {
  return try await withCheckedThrowingContinuation { continuation in
    URLSession.shared.dataTask(with: request) { data, response, err in
      if let err = err {
        continuation.resume(throwing: err)
        return
      }
      guard let data, let response else {
        continuation.resume(throwing: ApiClient.Error.missingDataOrResponse)
        return
      }
      continuation.resume(returning: (data, response))
    }.resume()
  }
}

private enum App {
  case wrap(MacAppRoute)
  static let router = OneOf {
    Route(.case(App.wrap)) {
      Method.post
      Path { "macos-app" }
      MacAppRoute.router
    }
  }
}

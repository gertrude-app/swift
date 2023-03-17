import Foundation
import MacAppRoute
import Models
import XCore

func response<T: Pair>(
  _ route: AuthedUserRoute,
  to pair: T.Type
) async throws -> T.Output {
  guard let token = await userToken.value?.rawValue else {
    throw AppError("Missing user token")
  }
  return try await request(root: .userAuthed(token, route), pair: T.self)
}

func response<T: Pair>(
  unauthed route: UnauthedRoute,
  to pair: T.Type
) async throws -> T.Output {
  try await request(root: .unauthed(route), pair: T.self)
}

// helpers

private func request<T: Pair>(
  root route: MacAppRoute,
  pair: T.Type
) async throws -> T.Output {
  let router = App.router.baseURL(await endpoint.value.absoluteString)
  let request = try router.request(for: .wrap(route))
  let (data, response) = try await data(for: request)
  if let httpResponse = response as? HTTPURLResponse,
     httpResponse.statusCode >= 300 {
    if let pqlError = try? JSON.decode(data, as: PqlError.self) {
      throw pqlError
    } else {
      throw AppError("Unexpected API error", unexpected: true)
    }
  }
  return try JSON.decode(data, as: T.Output.self)
}

// URLSession.data(for:) not available till macOS 12
private func data(for request: URLRequest) async throws -> (Data, URLResponse) {
  struct MissingDataOrResponse: Error {}
  return try await withCheckedThrowingContinuation { continuation in
    URLSession.shared.dataTask(with: request) { data, response, err in
      if let err = err {
        continuation.resume(throwing: err)
        return
      }
      guard let data = data, let response = response else {
        continuation.resume(throwing: MissingDataOrResponse())
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

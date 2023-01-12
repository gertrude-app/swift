import Combine
import MacAppRoute
import SharedCore
import XCore

func response<T: Pair>(
  _ route: AuthedUserRoute,
  to pair: T.Type
) async -> Result<T.Output, ApiClient.Error> {
  guard let token = Current.deviceStorage.getUUID(.userToken) else {
    return .failure(.precondition(T.name, "missing user token"))
  }
  return await response(root: .userAuthed(token, route), pair: T.self)
}

func response<T: Pair>(
  unauthed route: UnauthedRoute,
  to pair: T.Type
) async -> Result<T.Output, ApiClient.Error> {
  await response(root: .unauthed(route), pair: T.self)
}

extension Result {
  func mapVoid() -> Result<Void, Failure> {
    switch self {
    case .success:
      return .success(())
    case .failure(let error):
      return .failure(error)
    }
  }
}

// helpers

private enum WrappedRoute {
  case wrap(MacAppRoute)
  static let router = OneOf {
    Route(.case(WrappedRoute.wrap)) {
      Method.post
      Path { "macos-app" }
      MacAppRoute.router
    }
  }
}

private func response<T: Pair>(
  root route: MacAppRoute,
  pair: T.Type
) async -> Result<T.Output, ApiClient.Error> {
  let override = Current.deviceStorage.getURL(.pairQLEndpointOverride)
  let router = WrappedRoute
    .router
    .baseURL((override ?? SharedConstants.PAIRQL_ENDPOINT).absoluteString)
  do {
    let request = try router.request(for: .wrap(route))
    let (data, response) = try await data(for: request)
    if let httpResponse = response as? HTTPURLResponse,
       httpResponse.statusCode >= 300,
       let error = try? JSON.decode(data, as: PqlError.self) {
      log(.api(.pqlError(T.name, error)))
      return .failure(.pql(T.name, error))
    }
    let output = try JSON.decode(data, as: T.Output.self)
    log(.api(.receivedResponse(T.name)))
    return .success(output)
  } catch {
    log(.api(.genericError(T.name, error)))
    return .failure(.generic(T.name, error))
  }
}

// URLSession.data(for:) not available till macOS 12, this is a polyfill
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

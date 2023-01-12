import Foundation
import Shared

public enum NetworkError: Error {
  case invalidURL
  case emptyData
  case unknownError
}

public protocol RemoteJsonLoadable: Decodable {
  static func load(fromUrl: String, result: @escaping (Result<Self, Error>) -> Void)
}

public extension RemoteJsonLoadable {
  static func load(fromUrl: String, result: @escaping (Result<Self, Error>) -> Void) {
    guard let url = URL(string: fromUrl) else {
      result(.failure(NetworkError.invalidURL))
      return
    }
    let request = URLRequest(url: url)
    URLSession.perform(request, decode: Self.self, result: result)
  }
}

public protocol IPCTransmitable: Codable {}

extension URLSession {
  static func perform<T: Decodable>(
    _ request: URLRequest,
    decode decodable: T.Type,
    result: @escaping (Result<T, Error>) -> Void
  ) {
    URLSession.shared.dataTask(with: request) { data, _, error in
      if let error = error {
        result(.failure(error))
        return
      }

      guard let data = data else {
        result(.failure(NetworkError.emptyData))
        return
      }

      do {
        let object = try JSONDecoder().decode(decodable, from: data)
        result(.success(object))
      } catch {
        result(.failure(error))
      }

    }.resume()
  }
}

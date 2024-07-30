import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public enum HTTP {
  public enum AuthType: Sendable {
    case bearer(String)
    case basic(String, String)
    case basicUnencoded(String)
    case basicEncoded(String)
  }

  public enum Method: String, Sendable {
    case post = "POST"
    case get = "GET"
  }

  public static func postJson<Body: Encodable>(
    _ body: Body,
    to urlString: String,
    headers: [String: String] = [:],
    auth: AuthType? = nil,
    keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys
  ) async throws -> (Data, HTTPURLResponse) {
    var request = try urlRequest(to: urlString, method: .post, headers: headers, auth: auth)
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = keyEncodingStrategy
    request.httpBody = try encoder.encode(body)
    return try convertResponse(try await data(for: request))
  }

  public static func postJson<Body: Encodable, Response: Decodable>(
    _ body: Body,
    to urlString: String,
    decoding: Response.Type,
    headers: [String: String] = [:],
    auth: AuthType? = nil,
    keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys,
    keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys
  ) async throws -> Response {
    let (data, _) = try await postJson(
      body,
      to: urlString,
      headers: headers,
      auth: auth,
      keyEncodingStrategy: keyEncodingStrategy
    )
    return try decode(Response.self, from: data, using: keyDecodingStrategy)
  }

  public static func postFormUrlencoded(
    _ params: [String: String],
    to urlString: String,
    headers: [String: String] = [:],
    auth: AuthType? = nil
  ) async throws -> (Data, HTTPURLResponse) {
    var request = try urlRequest(to: urlString, method: .post, headers: headers, auth: auth)
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    // @TODO: should use URLComponents for correct encoding...
    // @see: https://www.advancedswift.com/a-guide-to-urls-in-swift/#create-url-string
    let query = params.map { key, value in "\(key)=\(value)" }.joined(separator: "&")
    request.httpBody = query.data(using: .utf8)
    return try convertResponse(await data(for: request))
  }

  public static func get(
    _ urlString: String,
    headers: [String: String] = [:],
    auth: AuthType? = nil
  ) async throws -> (Data, HTTPURLResponse) {
    let request = try urlRequest(to: urlString, method: .get, headers: headers, auth: auth)
    return try convertResponse(await data(for: request))
  }

  public static func get<T: Decodable>(
    _ urlString: String,
    decoding: T.Type,
    headers: [String: String] = [:],
    auth: AuthType? = nil,
    keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys
  ) async throws -> T {
    let (data, _) = try await get(urlString, headers: headers, auth: auth)
    return try decode(T.self, from: data, using: keyDecodingStrategy)
  }

  public static func post(
    _ urlString: String,
    headers: [String: String] = [:],
    auth: AuthType? = nil
  ) async throws -> (Data, HTTPURLResponse) {
    let request = try urlRequest(to: urlString, method: .post, headers: headers, auth: auth)
    return try convertResponse(await data(for: request))
  }

  public static func post<T: Decodable>(
    _ urlString: String,
    decoding: T.Type,
    headers: [String: String] = [:],
    auth: AuthType? = nil,
    keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys
  ) async throws -> T {
    let (data, _) = try await post(urlString, headers: headers, auth: auth)
    return try decode(T.self, from: data, using: keyDecodingStrategy)
  }

  public static func postFormUrlencoded<T: Decodable>(
    _ params: [String: String],
    to urlString: String,
    decoding: T.Type,
    headers: [String: String] = [:],
    auth: AuthType? = nil,
    keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys
  ) async throws -> T {
    let (data, _) = try await postFormUrlencoded(
      params,
      to: urlString,
      headers: headers,
      auth: auth
    )
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = keyDecodingStrategy
    return try decoder.decode(T.self, from: data)
  }
}

public enum HttpError: Error, LocalizedError {
  case invalidUrl(String)
  case base64EncodingFailed
  case decodingError(Error, String)
  case unexpectedResponseType
  case missingDataOrResponse

  public var errorDescription: String? {
    switch self {
    case .invalidUrl(let string):
      return "Invalid URL string: \(string)"
    case .base64EncodingFailed:
      return "base64Endoding failed"
    case .decodingError(let error, let raw):
      return "JSON decoding failed. Error=\(error), Raw=\(raw)"
    case .unexpectedResponseType:
      return "Unexpected response type, could not convert to HTTPURLResponse"
    case .missingDataOrResponse:
      return "Unexpectedly missing data or response"
    }
  }
}

// helpers

private func urlRequest(
  to urlString: String,
  method: HTTP.Method,
  headers: [String: String] = [:],
  auth: HTTP.AuthType? = nil
) throws -> URLRequest {
  guard let url = URL(string: urlString) else {
    throw HttpError.invalidUrl(urlString)
  }
  var request = URLRequest(url: url)
  request.httpMethod = method.rawValue
  headers.forEach { key, value in request.setValue(value, forHTTPHeaderField: key) }
  switch auth {
  case .bearer(let token):
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
  case .basicEncoded(let string):
    request.setValue("Basic \(string)", forHTTPHeaderField: "Authorization")
  case .basic(let username, let password):
    guard let data = "\(username):\(password)".data(using: .utf8) else {
      throw HttpError.base64EncodingFailed
    }
    let encoded = data.base64EncodedString()
    request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
  case .basicUnencoded(let string):
    guard let data = string.data(using: .utf8) else {
      throw HttpError.base64EncodingFailed
    }
    let encoded = data.base64EncodedString()
    request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
  case nil:
    break
  }
  return request
}

private func convertResponse(_ result: (Data, URLResponse)) throws
  -> (Data, HTTPURLResponse) {
  guard let httpResponse = result.1 as? HTTPURLResponse else {
    throw HttpError.unexpectedResponseType
  }
  return (result.0, httpResponse)
}

private func decode<T: Decodable>(
  _: T.Type,
  from data: Data,
  using keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys
) throws -> T {
  do {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = keyDecodingStrategy
    return try decoder.decode(T.self, from: data)
  } catch {
    throw HttpError.decodingError(error, String(data: data, encoding: .utf8) ?? "")
  }
}

// corelibsfoundation on Linux doesn't support URLSession.data(for:) async method,
// so recreating it here -- once this is no longer a limitation, remove and switch
// back just calling URLSession.shared.data(for:)
private func data(for request: URLRequest) async throws -> (Data, URLResponse) {
  try await withCheckedThrowingContinuation { continuation in
    URLSession.shared.dataTask(with: request) { data, response, err in
      if let err = err {
        continuation.resume(throwing: err)
        return
      }
      guard let data = data, let response = response else {
        continuation.resume(throwing: HttpError.missingDataOrResponse)
        return
      }
      continuation.resume(returning: (data, response))
    }.resume()
  }
}

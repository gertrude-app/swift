import Foundation

public enum XPC {
  public static func encode<T: Encodable>(
    _ value: T,
    fn: StaticString = #function
  ) throws -> Data {
    do {
      return try JSONEncoder().encode(value)
    } catch {
      throw XPCErr.encode(fn: "\(fn)", type: "\(T.self)", error: "\(error)")
    }
  }

  public static func decode<T: Decodable>(
    _ type: T.Type,
    from data: Data,
    fn: StaticString = #function
  ) throws -> T {
    do {
      return try JSONDecoder().decode(T.self, from: data)
    } catch {
      throw XPCErr.decode(fn: "\(fn)", type: "\(T.self)", error: "\(error)")
    }
  }

  public static func errorData(_ error: Error) -> Data {
    do {
      if let xpcError = error as? XPCErr {
        return try encode(xpcError)
      }
    } catch {}
    return Data(String(describing: error).utf8)
  }
}

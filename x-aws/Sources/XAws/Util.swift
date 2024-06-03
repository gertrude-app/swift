import Crypto
import Foundation

// implement functions required here:
// https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-query-string-auth.html
extension AWS.Util {
  static func lowercase(_ string: String) -> String {
    string.lowercased()
  }

  static func trim(_ string: String) -> String {
    string.trimmingCharacters(in: .whitespaces)
  }

  static func uriEncode(_ string: String, isObjectKeyName: Bool = false) -> String {
    let reserved = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.~"
    var allowed = CharacterSet(charactersIn: reserved)
    if isObjectKeyName {
      allowed.insert(charactersIn: "/")
    }
    return string.addingPercentEncoding(withAllowedCharacters: allowed)!
  }

  static func hex(_ data: Data) -> String {
    data.map { String(format: "%02hhx", $0) }.joined()
  }

  static func sha256(_ string: String) -> String {
    self.hex(Data(SHA256.hash(data: Data(string.utf8))))
  }

  static func hmac(_ key: Data, _ string: String) -> Data {
    let key = SymmetricKey(data: key)
    let hmac = HMAC<SHA256>.authenticationCode(for: Data(string.utf8), using: key)
    return Data(hmac)
  }

  static func hmac(_ key: String, _ string: String) -> Data {
    let key = SymmetricKey(data: Data(key.utf8))
    let hmac = HMAC<SHA256>.authenticationCode(for: Data(string.utf8), using: key)
    return Data(hmac)
  }

  static func timestamp(_ date: Date = Date()) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate, .withFullTime]
    return formatter.string(from: date)
      .replacingOccurrences(of: ":", with: "")
      .replacingOccurrences(of: "-", with: "")
  }

  static func yyyymmdd(_ date: Date = Date()) -> String {
    String(self.timestamp(date).prefix(8))
  }
}

extension AWS {
  enum Util {}
}

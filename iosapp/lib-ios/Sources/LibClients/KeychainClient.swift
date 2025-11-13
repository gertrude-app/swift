import Dependencies
import DependenciesMacros
import Foundation
import Security

@DependencyClient
struct KeychainClient: Sendable {
  var _load: @Sendable (_ key: Key) -> Data?
  var _save: @Sendable (_ key: Key, _ data: Data) -> Void
  var delete: @Sendable (_ key: Key) -> Void
}

extension KeychainClient {
  enum Key: String {
    case vendorId

    var secAttrAccount: String {
      "com.gertrude.ios.\(self.rawValue)"
    }
  }
}

extension KeychainClient {
  func loadVendorId() -> UUID? {
    if let data = self._load(.vendorId),
       let string = String(data: data, encoding: .utf8),
       let uuid = UUID(uuidString: string) {
      uuid
    } else {
      nil
    }
  }

  func save(vendorId: UUID) {
    let data = vendorId.uuidString.data(using: .utf8)!
    self._save(.vendorId, data)
  }
}

extension KeychainClient: DependencyKey {
  static var liveValue: KeychainClient {
    .init(
      _load: { key in
        let query: [String: Any] = [
          kSecClass as String: kSecClassGenericPassword,
          kSecAttrAccount as String: key.secAttrAccount,
          kSecReturnData as String: true,
          kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
           let data = result as? Data {
          return data
        } else {
          return nil
        }
      },
      _save: { key, data in
        let query: [String: Any] = [
          kSecClass as String: kSecClassGenericPassword,
          kSecAttrAccount as String: key.secAttrAccount,
          kSecValueData as String: data,
          kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
      },
      delete: { key in
        let query: [String: Any] = [
          kSecClass as String: kSecClassGenericPassword,
          kSecAttrAccount as String: key.secAttrAccount,
        ]
        SecItemDelete(query as CFDictionary)
      },
    )
  }
}

extension DependencyValues {
  var keychain: KeychainClient {
    get { self[KeychainClient.self] }
    set { self[KeychainClient.self] = newValue }
  }
}

#if DEBUG
  extension KeychainClient {
    static let mock = KeychainClient(
      _load: { key in
        switch key {
        case .vendorId:
          "DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF".data(using: .utf8)!
        }
      },
      _save: { _, _ in },
      delete: { _ in },
    )
  }
#endif

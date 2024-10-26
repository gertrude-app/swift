import Foundation

public extension UserDefaults {
  static let gertrude = UserDefaults(suiteName: "group.com.netrivet.gertrude-ios.app")!
}

public extension String {
  static var pairqlBase: String {
    "\(String.gertrudeApi)/pairql/ios-app"
  }

  static var gertrudeApi: String {
    #if DEBUG
      // just run-api-ip
      "http://192.168.10.227:8080"
    #else
      "https://api.gertrude.app"
    #endif
  }

  static var blockRulesStorageKey: String {
    "blockRules.v1"
  }
}

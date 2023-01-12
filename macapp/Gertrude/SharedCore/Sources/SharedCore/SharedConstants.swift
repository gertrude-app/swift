import Foundation

public enum SharedConstants {
  public static let APP_BUNDLE_ID = "WFN83LM943.com.netrivet.gertrude.app"
  public static let FILTER_EXTENSION_BUNDLE_ID = "WFN83LM943.com.netrivet.gertrude.filter-extension"
  public static let MACH_SERVICE_NAME = "WFN83LM943.com.netrivet.gertrude.group.mach-service"

  #if DEBUG
    public static let RELEASE_ENDPOINT =
      URL(string: "http://127.0.0.1:8082/releases")!
    public static let PAIRQL_ENDPOINT =
      URL(string: "http://127.0.0.1:8082/pairql")!
    public static let WEBSOCKET_ENDPOINT = URL(string: "http://127.0.0.1:8080/app")!
  #else
    public static let RELEASE_ENDPOINT =
      URL(string: "https://api.gertrude-app.com/releases")!
    public static let PAIRQL_ENDPOINT =
      URL(string: "https://api.gertrude-app.com/pairql")!
    public static let WEBSOCKET_ENDPOINT = URL(string: "https://api.gertrude-app.com/app")!
  #endif
}

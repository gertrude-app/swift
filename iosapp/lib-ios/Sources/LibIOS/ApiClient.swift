import Dependencies
import DependenciesMacros
import Foundation
import IOSRoute
import os.log

@DependencyClient
struct ApiClient: Sendable {
  var logEvent: @Sendable (_ id: String, _ detail: String?) async -> Void
}

extension ApiClient: TestDependencyKey {
  public static let testValue = ApiClient()
}

extension ApiClient: DependencyKey {
  public static var liveValue: ApiClient {
    ApiClient { id, detail in
      let payload = LogIOSEvent.Input(
        eventId: id,
        kind: "ios",
        deviceType: Device.current.type,
        iOSVersion: Device.current.iOSVersion,
        vendorId: Device.current.vendorId,
        detail: detail
      )
      do {
        let router = IOSRoute.router.baseURL(.gertrudeApi)
        var request = try router.request(for: .logIOSEvent(payload))
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.httpMethod = "POST"
        _ = try await URLSession.shared.data(for: request)
      } catch {
        os_log("[G•] error logging event: %{public}s", String(reflecting: error))
      }
    }
  }
}

extension DependencyValues {
  var api: ApiClient {
    get { self[ApiClient.self] }
    set { self[ApiClient.self] = newValue }
  }
}

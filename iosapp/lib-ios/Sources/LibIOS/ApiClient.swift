import Dependencies
import DependenciesMacros
import Foundation
import GertieIOS
import IOSRoute
import LibCore
import os.log

@DependencyClient
struct ApiClient: Sendable {
  var fetchBlockRules: @Sendable () async throws -> [BlockRule]
  var logEvent: @Sendable (_ id: String, _ detail: String?) async -> Void
}

extension ApiClient: TestDependencyKey {
  public static let testValue = ApiClient()
}

extension ApiClient: DependencyKey {
  public static var liveValue: ApiClient {
    ApiClient(
      fetchBlockRules: {
        @Dependency(\.device) var device
        let payload = BlockRules.Input(vendorId: device.vendorId)
        let (data, _) = try await request(route: .blockRules(payload))
        return try JSONDecoder().decode([BlockRule].self, from: data)
      },
      logEvent: { id, detail in
        @Dependency(\.device) var device
        let payload = LogIOSEvent.Input(
          eventId: id,
          kind: "ios",
          deviceType: device.type.rawValue,
          iOSVersion: device.iOSVersion,
          vendorId: device.vendorId,
          detail: detail
        )
        do {
          try await request(route: .logIOSEvent(payload))
        } catch {
          os_log("[G•] error logging event: %{public}s", String(reflecting: error))
        }
      }
    )
  }
}

@discardableResult
private func request(route: IOSRoute) async throws -> (Data, URLResponse) {
  let router = IOSRoute.router.baseURL(.pairqlBase)
  var request = try router.request(for: route)
  request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
  request.httpMethod = "POST"
  return try await URLSession.shared.data(for: request)
}

extension DependencyValues {
  var api: ApiClient {
    get { self[ApiClient.self] }
    set { self[ApiClient.self] = newValue }
  }
}

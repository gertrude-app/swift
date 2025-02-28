import Dependencies
import DependenciesMacros
import Foundation
import GertieIOS
import IOSRoute
import LibCore
import os.log

@DependencyClient
public struct ApiClient: Sendable {
  public var fetchBlockRules: @Sendable (_ vendorId: UUID, _ disabledGroups: [BlockGroup])
    async throws -> [BlockRule]
  public var fetchDefaultBlockRules: @Sendable (_ vendorId: UUID?) async throws -> [BlockRule]
  public var logEvent: @Sendable (_ id: String, _ detail: String?) async -> Void
}

extension ApiClient: TestDependencyKey {
  public static let testValue = ApiClient()
}

extension ApiClient: DependencyKey {
  public static var liveValue: ApiClient {
    let version = Bundle.main
      .infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    return ApiClient(
      fetchBlockRules: { vendorId, disabledGroups in
        let (data, _) = try await request(route: .blockRules_v2(.init(
          disabledGroups: disabledGroups,
          vendorId: vendorId,
          version: version
        )))
        return try JSONDecoder().decode([BlockRule].self, from: data)
      },
      fetchDefaultBlockRules: { vendorId in
        let (data, _) = try await request(route: .defaultBlockRules(.init(
          vendorId: vendorId,
          version: version
        )))
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

public extension DependencyValues {
  var api: ApiClient {
    get { self[ApiClient.self] }
    set { self[ApiClient.self] = newValue }
  }
}

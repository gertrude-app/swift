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
  public var recoveryDirective: @Sendable () async throws -> String?
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
        let (data, _) = try await request(route: .unauthed(.blockRules_v2(.init(
          disabledGroups: disabledGroups,
          vendorId: vendorId,
          version: version
        ))))
        return try JSONDecoder().decode([BlockRule].self, from: data)
      },
      fetchDefaultBlockRules: { vendorId in
        let (data, _) = try await request(route: .unauthed(.defaultBlockRules(.init(
          vendorId: vendorId,
          version: version
        ))))
        return try JSONDecoder().decode([BlockRule].self, from: data)
      },
      logEvent: { id, detail in
        @Dependency(\.device) var device
        let deviceData = await device.data()
        let payload = LogIOSEvent.Input(
          eventId: id,
          kind: "ios",
          deviceType: deviceData.type.rawValue,
          iOSVersion: deviceData.iOSVersion,
          vendorId: deviceData.vendorId,
          detail: detail
        )
        do {
          try await request(route: .unauthed(.logIOSEvent(payload)))
        } catch {
          os_log("[G•] error logging event: %{public}s", String(reflecting: error))
        }
      },
      recoveryDirective: {
        @Dependency(\.locale) var locale
        @Dependency(\.device) var device
        let deviceData = await device.data()
        let payload = RecoveryDirective.Input(
          vendorId: deviceData.vendorId,
          deviceType: deviceData.type.rawValue,
          iOSVersion: deviceData.iOSVersion,
          locale: locale.region?.identifier,
          version: version
        )
        let (data, _) = try await request(route: .unauthed(.recoveryDirective(payload)))
        let result = try JSONDecoder().decode(RecoveryDirective.Output.self, from: data)
        return result.directive
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

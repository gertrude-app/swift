import Dependencies
import DependenciesMacros
import Foundation
import GertieIOS
import IOSRoute
import LibCore
import os.log
import PairQL
import TaggedTime
import XCore

@DependencyClient
public struct ApiClient: Sendable {
  public var connectDevice: @Sendable (_ code: Int, _ vendorId: UUID) async throws
    -> ChildIOSDeviceData
  public var connectedRules: @Sendable (_ vendorId: UUID) async throws -> ConnectedRules.Output
  public var fetchBlockRules: @Sendable (_ vendorId: UUID, _ disabledGroups: [BlockGroup])
    async throws -> [BlockRule]
  public var fetchDefaultBlockRules: @Sendable (_ vendorId: UUID?) async throws -> [BlockRule]
  public var logEvent: @Sendable (_ id: String, _ detail: String?) async -> Void
  public var recoveryDirective: @Sendable () async throws -> String?
  public var setAuthToken: @Sendable (UUID?) async -> Void
}

extension ApiClient: TestDependencyKey {
  public static let testValue = ApiClient()
}

extension ApiClient: DependencyKey {
  public static var liveValue: ApiClient {
    let version = Bundle.main
      .infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    return ApiClient(
      connectDevice: { code, vendorId in
        @Dependency(\.device) var device
        let deviceData = await device.data()
        return try await output(
          from: ConnectDevice.self,
          withUnauthed: .connectDevice(.init(
            verificationCode: code,
            vendorId: vendorId,
            deviceType: deviceData.type.rawValue,
            appVersion: version,
            iosVersion: deviceData.iOSVersion
          ))
        )
      },
      connectedRules: { vendorId in
        @Dependency(\.device) var device
        let deviceData = await device.data()
        return try await output(
          from: ConnectedRules.self,
          with: .connectedRules(.init(
            vendorId: vendorId,
            deviceType: deviceData.type.rawValue,
            appVersion: version,
            iosVersion: deviceData.iOSVersion
          ))
        )
      },
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
      },
      setAuthToken: { token in
        _authToken.withLock { $0 = token }
      }
    )
  }
}

private let _authToken = Mutex<UUID?>(nil)

func output<T: Pair>(
  from pair: T.Type,
  with route: AuthedRoute
) async throws -> T.Output {
  guard let token = _authToken.withLock({ $0 }) else {
    throw ApiClient.Error.missingAuthToken
  }
  let (data, res) = try await request(route: .authed(token, route))
  if let httpResponse = res as? HTTPURLResponse,
     httpResponse.statusCode >= 300 {
    if let pqlError = try? JSON.decode(data, as: PqlError.self) {
      throw pqlError
    } else {
      throw ApiClient.Error.unexpectedError(statusCode: httpResponse.statusCode)
    }
  }
  return try JSON.decode(data, as: T.Output.self, [.isoDates])
}

func output<T: Pair>(
  from pair: T.Type,
  withUnauthed route: UnauthedRoute
) async throws -> T.Output {
  let (data, res) = try await request(route: .unauthed(route))
  if let httpResponse = res as? HTTPURLResponse,
     httpResponse.statusCode >= 300 {
    if let pqlError = try? JSON.decode(data, as: PqlError.self) {
      throw pqlError
    } else {
      throw ApiClient.Error.unexpectedError(statusCode: httpResponse.statusCode)
    }
  }
  return try JSON.decode(data, as: T.Output.self, [.isoDates])
}

public extension ApiClient {
  enum Error: Swift.Error {
    case missingAuthToken
    case missingDataOrResponse
    case unexpectedError(statusCode: Int)
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

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
  public var connectDevice: @Sendable (_ code: Int, _ vendorId: UUID)
    async throws -> ChildIOSDeviceData_b1
  public var connectedRules: @Sendable (_ vendorId: UUID)
    async throws -> ConnectedRules_b1.Output
  public var fetchBlockRules: @Sendable (_ vendorId: UUID, _ disabledGroups: [BlockGroup])
    async throws -> [BlockRule]
  public var fetchDefaultBlockRules: @Sendable (_ vendorId: UUID?) async throws -> [BlockRule]
  public var logEvent: @Sendable (_ id: String, _ detail: String?) async -> Void
  public var recoveryDirective: @Sendable () async throws -> String?
  public var setAuthToken: @Sendable (UUID?) async -> Void
  public var connectAccountFeatureFlag: @Sendable ()
    async throws -> ConnectAccountFeatureFlag.Output
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
          from: ConnectDevice_b1.self,
          withUnauthed: .connectDevice(.init(
            verificationCode: code,
            vendorId: vendorId,
            deviceType: deviceData.type.rawValue,
            appVersion: version,
            iosVersion: deviceData.iOSVersion,
          )),
        )
      },
      connectedRules: { vendorId in
        @Dependency(\.device) var device
        let deviceData = await device.data()
        return try await output(
          from: ConnectedRules_b1.self,
          with: .connectedRules(.init(
            vendorId: vendorId,
            deviceType: deviceData.type.rawValue,
            appVersion: version,
            iosVersion: deviceData.iOSVersion,
          )),
        )
      },
      fetchBlockRules: { vendorId, disabledGroups in
        let legacyRules = try await output(
          from: BlockRules_v2.self,
          withUnauthed: .blockRules_v2(.init(
            disabledGroups: disabledGroups,
            vendorId: vendorId,
            version: version,
          )),
        )
        return legacyRules.map(\.current)
      },
      fetchDefaultBlockRules: { vendorId in
        let legacyRules = try await output(
          from: DefaultBlockRules.self,
          withUnauthed: .defaultBlockRules(.init(
            vendorId: vendorId,
            version: version,
          )),
        )
        return legacyRules.map(\.current)
      },
      logEvent: { id, detail in
        @Dependency(\.device) var device
        let deviceData = await device.data()
        do {
          _ = try await output(
            from: LogIOSEvent.self,
            withUnauthed: .logIOSEvent(.init(
              eventId: id,
              kind: "ios",
              deviceType: deviceData.type.rawValue,
              iOSVersion: deviceData.iOSVersion,
              vendorId: deviceData.vendorId,
              detail: detail,
            )),
          )
        } catch {
          os_log("[G•] error logging event: %{public}s", String(reflecting: error))
        }
      },
      recoveryDirective: {
        @Dependency(\.locale) var locale
        @Dependency(\.device) var device
        let deviceData = await device.data()
        let result = try await output(
          from: RecoveryDirective.self,
          withUnauthed: .recoveryDirective(.init(
            vendorId: deviceData.vendorId,
            deviceType: deviceData.type.rawValue,
            iOSVersion: deviceData.iOSVersion,
            locale: locale.region?.identifier,
            version: version,
          )),
        )
        return result.directive
      },
      setAuthToken: { token in
        _authToken.withLock { $0 = token }
      },
      connectAccountFeatureFlag: {
        try await output(
          from: ConnectAccountFeatureFlag.self,
          withUnauthed: .connectAccountFeatureFlag,
        )
      },
    )
  }
}

private let _authToken = Mutex<UUID?>(nil)

func output<T: Pair>(
  from pair: T.Type,
  with route: AuthedRoute,
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
  withUnauthed route: UnauthedRoute,
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

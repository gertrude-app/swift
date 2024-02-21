import Combine
import Dependencies
import Foundation
import MacAppRoute

public struct AppClient: Sendable {
  public enum ColorScheme: String, Sendable, Equatable {
    case light
    case dark
  }

  public var colorScheme: @Sendable () -> ColorScheme
  public var colorSchemeChanges: @Sendable () -> AnyPublisher<ColorScheme, Never>
  public var disableLaunchAtLogin: @Sendable () async -> Void
  public var enableLaunchAtLogin: @Sendable () async -> Void
  public var isLaunchAtLoginEnabled: @Sendable () async -> Bool
  public var installLocation: @Sendable () -> URL
  public var installedVersion: @Sendable () -> String?
  public var quit: @Sendable () async -> Void
  public var relaunch: @Sendable () async throws -> Void

  public init(
    colorScheme: @escaping @Sendable () -> ColorScheme,
    colorSchemeChanges: @escaping @Sendable () -> AnyPublisher<ColorScheme, Never>,
    disableLaunchAtLogin: @escaping @Sendable () async -> Void,
    enableLaunchAtLogin: @escaping @Sendable () async -> Void,
    isLaunchAtLoginEnabled: @escaping @Sendable () async -> Bool,
    installLocation: @escaping @Sendable () -> URL,
    installedVersion: @escaping @Sendable () -> String?,
    quit: @escaping @Sendable () async -> Void,
    relaunch: @escaping @Sendable () async throws -> Void
  ) {
    self.colorScheme = colorScheme
    self.colorSchemeChanges = colorSchemeChanges
    self.disableLaunchAtLogin = disableLaunchAtLogin
    self.enableLaunchAtLogin = enableLaunchAtLogin
    self.isLaunchAtLoginEnabled = isLaunchAtLoginEnabled
    self.installLocation = installLocation
    self.installedVersion = installedVersion
    self.quit = quit
    self.relaunch = relaunch
  }
}

public extension AppClient {
  var inCorrectLocation: Bool {
    #if DEBUG
      if ProcessInfo.processInfo.environment["SWIFT_DETERMINISTIC_HASHING"] == nil {
        return true // we're running the debug build locally (not testing)
      }
    #endif
    // macOS won't install system extensions from outside /Applications
    return installLocation().path.starts(with: "/Applications")
  }
}

#if DEBUG
  public extension URL {
    static let inApplicationsDir = URL(fileURLWithPath: "/Applications/Gertrude.app")
  }
#endif

extension AppClient: TestDependencyKey {
  public static let testValue = Self(
    colorScheme: unimplemented("AppClient.colorScheme"),
    colorSchemeChanges: unimplemented("AppClient.colorSchemeChanges"),
    disableLaunchAtLogin: unimplemented("AppClient.disableLaunchAtLogin"),
    enableLaunchAtLogin: unimplemented("AppClient.enableLaunchAtLogin"),
    isLaunchAtLoginEnabled: unimplemented("AppClient.isLaunchAtLoginEnabled"),
    installLocation: unimplemented("AppClient.installLocation"),
    installedVersion: unimplemented("AppClient.installedVersion"),
    quit: unimplemented("AppClient.quit"),
    relaunch: unimplemented("AppClient.relaunch")
  )
  public static let mock = Self(
    colorScheme: { .light },
    colorSchemeChanges: { Empty().eraseToAnyPublisher() },
    disableLaunchAtLogin: {},
    enableLaunchAtLogin: {},
    isLaunchAtLoginEnabled: { true },
    installLocation: { URL(fileURLWithPath: "/Applications/Gertrude.app") },
    installedVersion: { "1.0.0" },
    quit: {},
    relaunch: {}
  )
}

public extension DependencyValues {
  var app: AppClient {
    get { self[AppClient.self] }
    set { self[AppClient.self] = newValue }
  }
}

public extension ApiClient {
  func appCheckIn(_ filterVersion: String?) async throws -> CheckIn.Output {
    @Dependency(\.app) var appClient
    return try await checkIn(
      .init(
        appVersion: appClient.installedVersion() ?? "unknown",
        filterVersion: filterVersion
      )
    )
  }
}

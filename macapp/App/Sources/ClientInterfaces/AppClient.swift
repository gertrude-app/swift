import Combine
import Core
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
  public var hasFullDiskAccess: @Sendable () async -> Bool
  public var isLaunchAtLoginEnabled: @Sendable () async -> Bool
  public var installLocation: @Sendable () -> URL
  public var installedVersion: @Sendable () -> String?
  public var preventScreenCaptureNag: @Sendable () async -> Result<Void, AppError>
  public var quit: @Sendable () async -> Void
  public var relaunch: @Sendable () async throws -> Void
  public var startRelaunchWatcher: @Sendable () async throws -> Void
  public var stopRelaunchWatcher: @Sendable () async -> Void

  public init(
    colorScheme: @escaping @Sendable () -> ColorScheme,
    colorSchemeChanges: @escaping @Sendable () -> AnyPublisher<ColorScheme, Never>,
    disableLaunchAtLogin: @escaping @Sendable () async -> Void,
    enableLaunchAtLogin: @escaping @Sendable () async -> Void,
    hasFullDiskAccess: @escaping @Sendable () async -> Bool,
    isLaunchAtLoginEnabled: @escaping @Sendable () async -> Bool,
    installLocation: @escaping @Sendable () -> URL,
    installedVersion: @escaping @Sendable () -> String?,
    preventScreenCaptureNag: @escaping @Sendable () async -> Result<Void, AppError>,
    quit: @escaping @Sendable () async -> Void,
    relaunch: @escaping @Sendable () async throws -> Void,
    startRelaunchWatcher: @escaping @Sendable () async throws -> Void,
    stopRelaunchWatcher: @escaping @Sendable () async -> Void
  ) {
    self.colorScheme = colorScheme
    self.colorSchemeChanges = colorSchemeChanges
    self.disableLaunchAtLogin = disableLaunchAtLogin
    self.enableLaunchAtLogin = enableLaunchAtLogin
    self.hasFullDiskAccess = hasFullDiskAccess
    self.isLaunchAtLoginEnabled = isLaunchAtLoginEnabled
    self.installLocation = installLocation
    self.installedVersion = installedVersion
    self.preventScreenCaptureNag = preventScreenCaptureNag
    self.quit = quit
    self.relaunch = relaunch
    self.startRelaunchWatcher = startRelaunchWatcher
    self.stopRelaunchWatcher = stopRelaunchWatcher
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
    return self.installLocation().path.starts(with: "/Applications")
  }
}

#if DEBUG
  public extension URL {
    static let inApplicationsDir = URL(fileURLWithPath: "/Applications/Gertrude.app")
  }
#endif

extension AppClient: TestDependencyKey {
  public static let testValue = Self(
    colorScheme: unimplemented("AppClient.colorScheme", placeholder: .light),
    colorSchemeChanges: unimplemented(
      "AppClient.colorSchemeChanges",
      placeholder: AnyPublisher(Empty())
    ),
    disableLaunchAtLogin: unimplemented("AppClient.disableLaunchAtLogin"),
    enableLaunchAtLogin: unimplemented("AppClient.enableLaunchAtLogin"),
    hasFullDiskAccess: unimplemented("AppClient.hasFullDiskAccess", placeholder: true),
    isLaunchAtLoginEnabled: unimplemented("AppClient.isLaunchAtLoginEnabled", placeholder: true),
    installLocation: unimplemented("AppClient.installLocation", placeholder: URL(string: "/")!),
    installedVersion: unimplemented("AppClient.installedVersion", placeholder: "2.5.0"),
    preventScreenCaptureNag: unimplemented(
      "AppClient.preventScreenCaptureNag",
      placeholder: .success(())
    ),
    quit: unimplemented("AppClient.quit"),
    relaunch: unimplemented("AppClient.relaunch"),
    startRelaunchWatcher: unimplemented("AppClient.startRelaunchWatcher"),
    stopRelaunchWatcher: unimplemented("AppClient.stopRelaunchWatcher")
  )
  public static let mock = Self(
    colorScheme: { .light },
    colorSchemeChanges: { Empty().eraseToAnyPublisher() },
    disableLaunchAtLogin: {},
    enableLaunchAtLogin: {},
    hasFullDiskAccess: { true },
    isLaunchAtLoginEnabled: { true },
    installLocation: { URL(fileURLWithPath: "/Applications/Gertrude.app") },
    installedVersion: { "1.0.0" },
    preventScreenCaptureNag: { .success(()) },
    quit: {},
    relaunch: {},
    startRelaunchWatcher: {},
    stopRelaunchWatcher: {}
  )
}

public extension DependencyValues {
  var app: AppClient {
    get { self[AppClient.self] }
    set { self[AppClient.self] = newValue }
  }
}

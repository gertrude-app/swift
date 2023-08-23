import Combine
import Dependencies
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
  public var installedVersion: @Sendable () -> String?
  public var quit: @Sendable () async -> Void

  public init(
    colorScheme: @escaping @Sendable () -> ColorScheme,
    colorSchemeChanges: @escaping @Sendable () -> AnyPublisher<ColorScheme, Never>,
    disableLaunchAtLogin: @escaping @Sendable () async -> Void,
    enableLaunchAtLogin: @escaping @Sendable () async -> Void,
    isLaunchAtLoginEnabled: @escaping @Sendable () async -> Bool,
    installedVersion: @escaping @Sendable () -> String?,
    quit: @escaping @Sendable () async -> Void
  ) {
    self.colorScheme = colorScheme
    self.colorSchemeChanges = colorSchemeChanges
    self.disableLaunchAtLogin = disableLaunchAtLogin
    self.enableLaunchAtLogin = enableLaunchAtLogin
    self.isLaunchAtLoginEnabled = isLaunchAtLoginEnabled
    self.installedVersion = installedVersion
    self.quit = quit
  }
}

extension AppClient: TestDependencyKey {
  public static let testValue = Self(
    colorScheme: { .light },
    colorSchemeChanges: { Empty().eraseToAnyPublisher() },
    disableLaunchAtLogin: {},
    enableLaunchAtLogin: {},
    isLaunchAtLoginEnabled: { true },
    installedVersion: { "1.0.0" },
    quit: {}
  )
}

public extension DependencyValues {
  var app: AppClient {
    get { self[AppClient.self] }
    set { self[AppClient.self] = newValue }
  }
}

public extension ApiClient {
  func appCheckIn() async throws -> CheckIn.Output {
    @Dependency(\.app) var appClient
    return try await checkIn(
      .init(appVersion: appClient.installedVersion() ?? "unknown")
    )
  }
}

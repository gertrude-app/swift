import Dependencies
import FamilyControls
import NetworkExtension
import os.log

public struct ExtensionClient: Sendable {
  public var requestAuthorization: @Sendable () async -> Result<Void, AuthFailureReason>
  public var installFilter: @Sendable () async -> Result<Void, FilterInstallError>
  public var filterRunning: @Sendable () async -> Bool
  public var cleanupForRetry: @Sendable () async -> Void
}

extension ExtensionClient: DependencyKey {
  public static let liveValue = ExtensionClient(
    requestAuthorization: {
      #if targetEnvironment(simulator)
        return .success(())
      #elseif os(iOS)
        do {
          try await AuthorizationCenter.shared.requestAuthorization(for: .child)
          return .success(())
        } catch let familyError as FamilyControlsError {
          switch familyError {
          case .invalidAccountType:
            return .failure(.invalidAccountType)
          case .authorizationConflict:
            return .failure(.authorizationConflict)
          case .authorizationCanceled:
            return .failure(.authorizationCanceled)
          case .networkError:
            return .failure(.networkError)
          case .authenticationMethodUnavailable:
            return .failure(.passcodeRequired)
          case .restricted:
            return .failure(.restricted)
          case .unavailable:
            return .failure(.unexpected(.unavailable))
          case .invalidArgument:
            return .failure(.unexpected(.invalidArgument))
          @unknown default:
            return .failure(.other(String(reflecting: familyError)))
          }
        } catch {
          return .failure(.other(String(reflecting: error)))
        }
      #else
        return .failure(.other("unexpected OS"))
      #endif
    },
    installFilter: {
      #if targetEnvironment(simulator)
        UserDefaults.gertrude.setValue(true, forKey: "simulatorFilterInstalled")
        return .success(())
      #else
        // not sure this is necessary, but doesn't seem to hurt and might ensure clean slate
        try? await NEFilterManager.shared().removeFromPreferences()

        if NEFilterManager.shared().providerConfiguration == nil {
          let newConfiguration = NEFilterProviderConfiguration()
          newConfiguration.username = "Gertrude"
          newConfiguration.organization = "Gertrude"
          #if os(iOS)
            newConfiguration.filterBrowsers = true
          #endif
          newConfiguration.filterSockets = true
          NEFilterManager.shared().providerConfiguration = newConfiguration
        }
        NEFilterManager.shared().isEnabled = true
        do {
          try await NEFilterManager.shared().saveToPreferences()
          return .success(())
        } catch {
          switch NEFilterManagerError(rawValue: (error as NSError).code) {
          case .some(.configurationInvalid):
            return .failure(.configurationInvalid)
          case .some(.configurationDisabled):
            return .failure(.configurationDisabled)
          case .some(.configurationStale):
            return .failure(.configurationStale)
          case .some(.configurationCannotBeRemoved):
            return .failure(.configurationCannotBeRemoved)
          case .some(.configurationPermissionDenied):
            return .failure(.configurationPermissionDenied)
          case .some(.configurationInternalError):
            return .failure(.configurationInternalError)
          case .none:
            return .failure(.unexpected(String(reflecting: error)))
          @unknown default:
            return .failure(.unexpected(String(reflecting: error)))
          }
        }
      #endif
    },
    filterRunning: {
      #if targetEnvironment(simulator)
        return UserDefaults.gertrude.bool(forKey: "simulatorFilterInstalled")
      #else
        do {
          try await NEFilterManager.shared().loadFromPreferences()
          return NEFilterManager.shared().isEnabled
        } catch {
          os_log(
            "[G•] error loading preferences: %{public}s",
            String(reflecting: error)
          )
          return false
        }
      #endif
    },
    cleanupForRetry: {
      NEFilterManager.shared().providerConfiguration = nil
      try? await NEFilterManager.shared().removeFromPreferences()
      #if os(iOS)
        AuthorizationCenter.shared.revokeAuthorization { _ in }
      #endif
    }
  )
}

extension ExtensionClient: TestDependencyKey {
  public static let testValue = ExtensionClient(
    requestAuthorization: { .success(()) },
    installFilter: { .success(()) },
    filterRunning: { false },
    cleanupForRetry: {}
  )
}

public extension DependencyValues {
  var systemExtension: ExtensionClient {
    get { self[ExtensionClient.self] }
    set { self[ExtensionClient.self] = newValue }
  }
}

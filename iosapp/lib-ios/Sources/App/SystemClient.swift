import Dependencies
import FamilyControls
import NetworkExtension
import os.log

struct SystemClient: Sendable {
  var requestAuthorization: @Sendable () async -> Result<Void, AuthFailureReason>
  var installFilter: @Sendable () async -> Result<Void, FilterInstallError>
  var filterRunning: @Sendable () async -> Bool
}

extension SystemClient: DependencyKey {
  public static let liveValue = SystemClient(
    requestAuthorization: {
      #if os(iOS)
        do {
          #if DEBUG
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
          #else
            try await AuthorizationCenter.shared.requestAuthorization(for: .child)
          #endif
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
            return .failure(.unexpected(.restricted))
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
      #endif
      return .success(())
    },
    installFilter: {
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
    },
    filterRunning: {
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
    }
  )
}

extension SystemClient: TestDependencyKey {
  public static let testValue = SystemClient(
    requestAuthorization: { .success(()) },
    installFilter: { .success(()) },
    filterRunning: { false }
  )
}

extension DependencyValues {
  var system: SystemClient {
    get { self[SystemClient.self] }
    set { self[SystemClient.self] = newValue }
  }
}
